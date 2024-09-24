//
//  HomeViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/11.
//

import UIKit
import SnapKit
import WeatherKit
import CoreLocation
import FirebaseFirestore
import MJRefresh
import Alamofire
import Kingfisher
import FirebaseAuth

class HomeViewController: UIViewController {
    
    private let locationManager = LocationManager()
    private let randomTripEntryButton = UIButton(type: .system)
    private let recommendRandomTripView = UIView()
    private let homeTableView = UITableView()
    private let popupView = PopUpView()
    
    var likeCount = String()
    var bookmarkCount = String()
    var likeButtonIsSelected = Bool()
    var isUpdatingLikeStatus = false
    
    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        //        uploadTripsToFirebase()
        //        uploadPlaces()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "首頁"
        
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.deepBlue // 修改為你想要的顏色
            ]
        
        view.backgroundColor = UIColor(resource: .backgroundGray)
        homeTableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        popupView.delegate = self
        observeLikeCountChanges()
        setupUI()
        setupTableView()
        setupPullToRefresh()
        uploadTripData()
        // 从 Firebase 加载 posts
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.homeTableView.reloadData()
        }
        setupLocationUpdates()
        setupUserProfileImage()
        
    }
    
    func setupUserProfileImage() {
        let avatarImageView = UIImageView()

        // 設定頭像的樣式
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.borderWidth = 0.5
        avatarImageView.layer.borderColor = UIColor.deepBlue.cgColor
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true

        // 將頭像圖片視圖添加到主視圖中
        self.view.addSubview(avatarImageView)

        // 設置位置約束
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(-50)  // 調整頂部偏移量
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(-20)
        }

        // 確保從 UserDefaults 中獲取正確的 userId
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("未找到當前用戶的 userId")
            return
        }

        // 使用 Firebase 的 addSnapshotListener 來監聽 photo 字段變化
        let userRef = FirebaseManager.shared.db.collection("users").document(currentUserId)
        
        userRef.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("監聽用戶資料失敗: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists, let data = document.data() else {
                print("無法找到用戶資料")
                return
            }
            
            // 獲取 photo URL 並更新頭像
            if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                DispatchQueue.main.async {
                    // 使用 Kingfisher 加載圖片
                    avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                }
            } else {
                print("無法獲取照片 URL")
            }
        }
    }

    func observeLikeCountChanges() {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId")
            return
        }

        // 獲取對應的貼文
        for (index, postData) in postsArray.enumerated() {
            let postId = postData["id"] as? String ?? ""
            let postRef = Firestore.firestore().collection("posts").document(postId)
            
            // 使用 addSnapshotListener 監聽貼文的變化
            postRef.addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if self.isUpdatingLikeStatus {
                    return  // 如果正在更新，暫停監聽
                }
                
                if let error = error {
                    print("監聽按讚數量變化時出錯: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(), let likesAccount = data["likesAccount"] as? [String] else {
                    print("無法加載按讚數據")
                    return
                }

                // 更新 UI
                DispatchQueue.main.async {
                    if let cell = self.homeTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? UserTableViewCell {
                        cell.likeCountLabel.text = String(likesAccount.count)
                        cell.likeButton.isSelected = likesAccount.contains(currentUserId)
                    }
                }
            }
        }
    }

    
    func setupLocationUpdates() {
        // 設定位置更新的回調
        locationManager.onLocationUpdate = { [weak self] location in
            guard let self = self else { return }
            //                weatherManager.fetchWeather(for: location)
        }
        // 啟動位置更新
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 每次回到這個頁面時重新加載資料
        FirebaseManager.shared.loadPosts { [weak self] postsArray in
            self?.postsArray = postsArray
            DispatchQueue.main.async {
                self?.homeTableView.reloadData() // 確保 UI 更新
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func setupUI() {
        view.addSubview(recommendRandomTripView)
        
        // 添加圓角效果
        recommendRandomTripView.layer.cornerRadius = 20
        recommendRandomTripView.layer.masksToBounds = true
        
        recommendRandomTripView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(100)
        }
        
        recommendRandomTripView.backgroundColor = .white
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recommendRandomTripView.addGestureRecognizer(tapGesture)
        
        // 在 recommendRandomTripView 裡面添加 UILabel
        let titleLabel = UILabel()
        titleLabel.text = "# 時令推薦"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor(resource: .deepBlue)
        recommendRandomTripView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView).offset(20)
            make.leading.equalTo(recommendRandomTripView).offset(15)
        }
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "下雨的時候就是要......"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor(resource: .deepBlue)
        recommendRandomTripView.addSubview(descriptionLabel)
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
    }
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        randomTripEntryButtonDidTapped()
    }
    
    func setupPullToRefresh() {
        // 添加下拉刷新
        homeTableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshData))
    }
    
    @objc func refreshData() {
        FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
            self.postsArray.insert(contentsOf: newPosts, at: 0)
            self.homeTableView.reloadData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 結束刷新
            self.homeTableView.mj_header?.endRefreshing()
        }
    }
    
    @objc func randomTripEntryButtonDidTapped() {
        FirebaseManager.shared.loadAllTrips { [weak self] trips in
            guard let self = self else { return }
            
            if let randomTrip = trips.randomElement() {
                self.randomTrip = randomTrip
                
                let placeIds = randomTrip.places.map { $0.id }
                
                FirebaseManager.shared.loadPlaces(placeIds: placeIds) { places in
                    self.popupView.showPopup(on: self.view, with: randomTrip)
                    
                    self.popupView.tapCollectButton = { [weak self] in
                        guard let self = self else { return }
                        
                        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
                            print("未找到 userId")
                            return
                        }
                        
                        FirebaseManager.shared.updateUserTripCollections(userId: userId, tripId: randomTrip.id) { success in
                            if success {
                                print("收藏成功")
                            } else {
                                print("收藏失敗")
                            }
                        }
                    }
                }
            }
        }
    }
}

extension HomeViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = randomTrip
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        homeTableView.dataSource = self
        homeTableView.delegate = self
        
        view.addSubview(homeTableView)
        homeTableView.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView.snp.bottom).offset(10)
            make.width.equalTo(recommendRandomTripView)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
            make.centerX.equalTo(view)
        }
        
        // 添加圓角效果
        homeTableView.layer.cornerRadius = 20
        homeTableView.layer.masksToBounds = true
        
        homeTableView.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = homeTableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        let postData = postsArray[indexPath.row]
        
        guard let cell = cell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.titleLabel.text = postsArray[indexPath.row]["title"] as? String
        cell.contentLabel.text = postData["content"] as? String
        cell.likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        cell.likeCountLabel.text = likeCount
        
        if let createdAtTimestamp = postData["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        // 使用貼文的發布者 userId 來獲取發布者的頭像
        if let postUserId = postData["userId"] as? String {
            FirebaseManager.shared.fetchUserData(userId: postUserId) { result in
                switch result {
                case .success(let data):
                    if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                        DispatchQueue.main.async {
                            cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                        }
                    }
                case .failure(let error):
                    print("加載貼文發布者大頭貼失敗: \(error.localizedDescription)")
                }
            }
        } else {
            print("貼文缺少 userId")
        }
        
        // 從 UserDefaults 中獲取當前使用者的 userId
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("未找到當前使用者的 userId")
            return cell
        }
        
        // 檢查貼文是否已被當前用戶收藏
        FirebaseManager.shared.isContentBookmarked(forUserId: currentUserId, id: postsArray[indexPath.row]["id"] as? String ?? "") { isBookmarked in
            cell.collectButton.isSelected = isBookmarked
        }
        
        // 加載所有的貼文數據
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == postData["id"] as? String
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = String(likesAccount.count)
                    cell.likeButton.isSelected = likesAccount.contains(currentUserId) // 依據是否按讚來設置狀態
                }
            } else {
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = "0"
                    cell.likeButton.isSelected = false // 如果沒有找到數據，按鈕設置為未選中
                }
            }
        }
        
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post = postsArray[indexPath.row]
        
        // 初始化 ArticleViewController
        let articleVC = ArticleViewController()
        
        // 傳遞貼文的資料
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                print("找到的 userName: \(userName)")
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
                articleVC.tripId = post["tripId"] as? String ?? ""
                articleVC.likeAccounts = post["likeAccount"] as? [String] ?? []
                
                if let createdAtTimestamp = post["createdAt"] as? Timestamp {
                    let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                    articleVC.articleDate = createdAtString
                }
                
                articleVC.authorId = post["userId"] as? String ?? ""
                articleVC.postId = post["id"] as? String ?? ""
                articleVC.bookmarkAccounts = post["bookmarkAccount"] as? [String] ?? []
                
                self.navigationController?.pushViewController(articleVC, animated: true)
            } else {
                print("未找到對應的 userName")
            }
        }
    }
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()

        // 暫停監聽
        isUpdatingLikeStatus = true

        let point = sender.convert(CGPoint.zero, to: homeTableView)

        if let indexPath = homeTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""

            // 使用 userId 從 UserDefaults 中獲取
            guard let userId = UserDefaults.standard.string(forKey: "userId") else {
                print("未找到 userId")
                return
            }

            saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
                if success {
                    print("按讚成功")
                    self.observeLikeCountChanges()  // 恢復監聽

                } else {
                    print("取消按讚失敗")
                    sender.isSelected.toggle()
                }
                // 完成後恢復監聽
                self.isUpdatingLikeStatus = false
            }
        }
    }

    func saveLikeData(postId: String, userId: String, isLiked: Bool, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        if isLiked {
            // 使用 arrayUnion 將 userId 添加到 likesAccount 列表中
            postRef.updateData([
                "likesAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("按讚失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("按讚成功，已更新資料")
                    completion(true)
                }
            }
        } else {
            // 使用 arrayRemove 將 userId 從 likesAccount 列表中移除
            postRef.updateData([
                "likesAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消按讚失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("取消按讚成功，已更新資料")
                    completion(true)
                }
            }
        }
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: homeTableView)
        
        if let indexPath = homeTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            
            guard let userId = UserDefaults.standard.string(forKey: "userId") else {
                print("未找到 userId")
                return
            }
            
            var bookmarkAccount = postData["bookmarkAccount"] as? [String] ?? []
            
            if sender.isSelected {
                if !bookmarkAccount.contains(userId) {
                    bookmarkAccount.append(userId)
                }
                
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        FirebaseManager.shared.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                            if let error = error {
                                print("Failed to update bookmarkAccount: \(error)")
                            } else {
                                print("收藏成功")
                            }
                        }
                    } else {
                        print("收藏失敗")
                    }
                }
            } else {
                bookmarkAccount.removeAll { $0 == userId }
                
                FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                    if success {
                        FirebaseManager.shared.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                            if let error = error {
                                print("Failed to update bookmarkAccount: \(error)")
                            } else {
                                print("取消收藏成功")
                            }
                        }
                    } else {
                        print("取消收藏失敗")
                    }
                }
            }
        }
    }

    
    func uploadTripsToFirebase() {
        let db = Firestore.firestore()
        
        // 第一筆資料
        let trip1 = Trip(
            poem: Poem(
                title: "〈夜宿山寺〉",
                poetry: "李白",
                original: ["危樓高百尺，手可摘星辰。", "不敢高聲語，恐驚天上人。"],
                translation: ["山上寺院的高樓真高啊，好像有一百尺的樣子，人在樓上好像一伸手就可以摘下天上的星星。",
                              "站在這裡，我不敢大聲說話，唯恐驚動天上的神仙。"],
                secretTexts: ["李白自號「青蓮居士」，源於《維摩詰經》的「青蓮」，展現他對佛教的崇敬和對維摩詘生活方式的嚮往。他不僅在詩中多次引用「青蓮」，還將維摩詘視為自己的精神榜樣，特別推崇《維摩詰經》中的「入諸酒肆，能立其志」的教義。"],
                situationText: ["台北101的觀景台是城市中最高的地方，從這裡俯瞰整個台北，感受到與天空接近的高度。站在這樣的高處，彷彿一個輕聲細語就能驚擾天上的人，體會詩中的敬畏與謙卑之感。"]
            ),
            id: "SKnCdn2SK9D4HjYnE9ll",
            places: [PlaceId(id: "f9E9Xc0p7aQaDBmqgv2K")],
            tag: 1,
            season: 4,
            weather: 2,
            startTime: 2
        )
        
        // 第二筆資料
        let trip2 = Trip(
            poem: Poem(
                title: "〈酬張少府〉",
                poetry: "王維",
                original: ["晚年惟好靜，萬事不關心。", "自顧無長策，空知返舊林。", "松風吹解帶，山月照彈琴。", "君問窮通理，漁歌入浦深。"],
                translation: ["到了晚年只喜歡清靜，對什麼事情都漠不關心。",
                              "自思沒有高策可以報國，只要求歸隱家鄉的山林。",
                              "寬解衣帶對著松風乘涼，山月高照正好弄弦彈琴。",
                              "若問窮困通達的道理，請聽水浦深處漁歌聲音。"],
                secretTexts: ["王維全家皆虔信佛法，茹素戒殺。王維母親崔氏在他很小的時候就帶發修行，一生「褐衣蔬食，持戒安禪」。",
                              "天寶末年，安祿山攻佔長安，皇室倉皇西逃，王維不及逃出，為叛軍所俘，並遭軟禁於洛陽菩提寺。"],
                situationText: ["步行登山：在登山途中，放慢腳步，感受山中的寧靜，聆聽松風和鳥鳴，仿佛在松風吹拂中，體驗詩中「解帶」的放鬆感。",
                                "坐在碼頭的長椅上，看著海面，思索關於人生的困境與順遂，就像詩中的「君問窮通理」。"]
            ),
            id: "p8oLRKdIRenhXwJy4gs0",
            places: [PlaceId(id: "Xyn45Kl2hyXMFQDuhyBD"), PlaceId(id: "eFqN1Bs4d8nd27GPq7dk")],
            tag: 2,
            season: 4,
            weather: 2,
            startTime: 2
        )
        
        // 第三筆資料
        let trip3 = Trip(
            poem: Poem(
                title: "〈感諷五首．其三〉",
                poetry: "李賀",
                original: ["南山何其悲，鬼雨灑空草！", "長安夜半秋，風前幾人老？", "低迷黃昏徑，裊裊青櫟道；", "月午樹無影，一山唯白曉，", "漆炬迎新人，幽壙螢擾擾。"],
                translation: ["南山是多麼的悲涼，鬼雨灑落在空曠的草地上。",
                              "長安的深夜已是秋天，在風中不知多少人已經變老。",
                              "黃昏的路徑彷彿籠罩著一層迷霧，青櫟樹的道路上飄著悠長的微風。",
                              "夜半的月亮高懸，樹木卻無影，整座山上只有白色的晨曦。",
                              "漆黑的火炬迎接著新來的人，幽暗的墓穴中螢火蟲在四處飛舞。"],
                secretTexts: ["李賀經常騎著一匹瘦馬，帶著小童子邊走邊思索，一旦有了好句子或是來了靈感，便把所想到的靈感急速記錄下來，投進小童子背著的小錦囊裡。",
                              "李賀的詩想像力豐富，意境詭異華麗，常用些險韻奇字。",
                              "李賀只活了短短二十七歲。他經歷了安史之亂帶來的巨大衝擊。"],
                situationText: ["當細雨輕灑於廣袤的草地上，水霧繚繞，彷彿鬼雨隨風飄落，帶來一種淒美的氛圍。",
                                "夕陽西下，餘暉灑在蜿蜒的山徑間，步道旁的樹木枝葉隨風輕搖。"]
            ),
            id: "u9QgkOcQsZZh90D6SAfc",
            places: [PlaceId(id: "CbCsS208lUh4OVNXedcB"), PlaceId(id: "NsqhxJyJxtv0SPnbDUqi"), PlaceId(id: "Q4yAOM6yUTOru6YqExsJ")],
            tag: 0,
            season: 2,
            weather: 1,
            startTime: 1
        )
        
        // 上傳資料到 Firebase
        let trips = [trip1, trip2, trip3]
        
        for trip in trips {
            let tripData: [String: Any] = [
                "id": trip.id,
                "places": trip.places.map { ["id": $0.id] },
                "poem": [
                    "title": trip.poem.title,
                    "poetry": trip.poem.poetry,
                    "original": trip.poem.original,
                    "translation": trip.poem.translation,
                    "secretTexts": trip.poem.secretTexts,
                    "situationText": trip.poem.situationText
                ],
                "tag": trip.tag,
                "season": trip.season,
                "weather": trip.weather,
                "startTime": trip.startTime
            ]
            
            // 儲存到 Firebase 中
            db.collection("trips").document(trip.id).setData(tripData) { error in
                if let error = error {
                    print("Error uploading trip \(trip.id): \(error.localizedDescription)")
                } else {
                    print("Successfully uploaded trip \(trip.id)")
                }
            }
        }
    }
    
    
    func uploadTripData() {
        let db = Firestore.firestore()
        
        // 构建 trip 数据
        let tripData: [String: Any] = [
            "id": "u9QgkOcQsZZh90D6SAfc",
            "places": [
                [
                    "id": "CbCsS208lUh4OVNXedcB"
                ],
                [
                    "id": "NsqhxJyJxtv0SPnbDUqi"
                ],
                [
                    "id": "Q4yAOM6yUTOru6YqExsJ"
                ]
            ],
            "poem": [
                "original": [
                    "南山何其悲，鬼雨灑空草！",
                    "長安夜半秋，風前幾人老？",
                    "低迷黃昏徑，裊裊青櫟道；",
                    "月午樹無影，一山唯白曉，",
                    "漆炬迎新人，幽壙螢擾擾。"
                ],
                "poetry": "李賀",
                "secretTexts": [
                    "李賀經常騎著一匹瘦馬，帶著小童子邊走邊思索，一旦有了好句子或是來了靈感，便把所想到的靈感急速記錄下來，投進小童子背著的小錦囊裡。",
                    "李賀的詩想像力豐富，意境詭異華麗，常用些險韻奇字。",
                    "李賀只活了短短二十七歲。他經歷了安史之亂帶來的巨大衝擊。"
                ],
                "situationText": [
                    "當細雨輕灑於廣袤的草地上，水霧繚繞，彷彿鬼雨隨風飄落，帶來一種淒美的氛圍。",
                    "夕陽西下，餘暉灑在蜿蜒的山徑間，步道旁的樹木枝葉隨風輕搖。"
                ],
                "title": "〈感諷五首．其三〉",
                "translation": [
                    "南山是多麼的悲涼，鬼雨灑落在空曠的草地上。",
                    "長安的深夜已是秋天，在風中不知多少人已經變老。",
                    "黃昏的路徑彷彿籠罩著一層迷霧，青櫟樹的道路上飄著悠長的微風。",
                    "夜半的月亮高懸，樹木卻無影，整座山上只有白色的晨曦。",
                    "漆黑的火炬迎接著新來的人，幽暗的墓穴中螢火蟲在四處飛舞。"
                ]
            ],
            "season": 2,
            "startTime": 1,
            "tag": 0,
            "weather": 1
        ]
        
        // 上传到 Firestore trips 集合中
        db.collection("trips").document("u9QgkOcQsZZh90D6SAfc").setData(tripData) { error in
            if let error = error {
                print("上传数据失败: \(error.localizedDescription)")
            } else {
                print("数据上传成功")
            }
        }
    }
}

