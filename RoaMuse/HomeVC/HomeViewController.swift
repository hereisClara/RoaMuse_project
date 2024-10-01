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
    
    let bottomSheetView = UIView()
        let backgroundView = UIView() // 半透明背景
        let sheetHeight: CGFloat = 300 // 選單高度
    
    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        findBestMatchedPoem(currentSeason: getCurrentSeason(), currentWeather: 0, currentTime: getCurrentSeason())
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        //        uploadTripsToFirebase()
        //        uploadPlaces()
        updatePoemData()
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
//        uploadTripData()
        // 从 Firebase 加载 posts
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.homeTableView.reloadData()
        }
        setupLocationUpdates()
        setupUserProfileImage()
        setupBottomSheet()
    }
    
    func setupBottomSheet() {
        // 初始化背景蒙層
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.frame = self.view.bounds
        backgroundView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        backgroundView.addGestureRecognizer(tapGesture)
        
        // 初始化底部選單視圖
        bottomSheetView.backgroundColor = .white
        bottomSheetView.layer.cornerRadius = 15
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // 設置初始位置在螢幕下方
        bottomSheetView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: sheetHeight)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(backgroundView)
            window.addSubview(bottomSheetView)
        }
        
        // 在選單視圖內部添加按鈕
        let saveButton = createButton(title: "刪除貼文")
        let impeachButton = createButton(title: "檢舉貼文")
        let blockButton = createButton(title: "封鎖用戶")
        let cancelButton = createButton(title: "取消", textColor: .red)
        
        let stackView = UIStackView(arrangedSubviews: [saveButton, impeachButton, blockButton, cancelButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        bottomSheetView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(bottomSheetView.snp.top).offset(20)
            make.leading.equalTo(bottomSheetView.snp.leading).offset(20)
            make.trailing.equalTo(bottomSheetView.snp.trailing).offset(-20)
        }
    }
    
    func createButton(title: String, textColor: UIColor = .black) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .clear
        return button
    }
    
    // 顯示彈窗
    func showBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: self.view.frame.height - self.sheetHeight, width: self.view.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 1
        }
    }

    // 隱藏彈窗
    @objc func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 0
        }
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

                let placeIds = randomTrip.placeIds  // 確認是否有 placeIds
                
                FirebaseManager.shared.loadPlaces(placeIds: placeIds) { places in
                    
                    let city = "台北市" // 可根據 places 的信息設置
                    let districts = ["大安區", "信義區"] // 根據 places 設置區域
                    
                    // 呼叫 showPopup 彈出視圖
                    self.popupView.showPopup(on: self.view, with: randomTrip, city: city, districts: districts)
                    
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
        
        homeTableView.rowHeight = UITableView.automaticDimension
        homeTableView.estimatedRowHeight = 250
        
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
        cell.configurePhotoStackView(with: postData["photoUrls"] as? [String] ?? [])
        //        homeTableView.layoutIfNeeded()
        
        cell.configureMoreButton {
            self.showBottomSheet()  // 顯示彈窗
        }
        
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
    
    func updatePoemData() {
        // 確定要更新的文件 ID
        let poemId = "sH9huntnRR2BNeQqEhrp"  // 該資料的 ID
        let db = Firestore.firestore()
        
        // 準備新的資料
        let newFields: [String: Any] = [
            "season": 3,
            "weather": 3,
            "time": 2
        ]
        
        // 更新指定 ID 的文檔
        db.collection("poems").document(poemId).updateData(newFields) { error in
            if let error = error {
                print("更新失敗: \(error.localizedDescription)")
            } else {
                print("資料已成功更新")
            }
        }
    }

}

extension HomeViewController {
    
    func getCurrentSeason() -> Int {
        let month = Calendar.current.component(.month, from: Date())

        switch month {
        case 3...5:
            return 1 // 春天
        case 6...8:
            return 2 // 夏天
        case 9...11:
            return 3 // 秋天
        default:
            return 4 // 冬天
        }
    }

    func getCurrentTimeOfDay() -> Int {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5...11:
            return 1 // 白天
        case 12...17:
            return 2 // 傍晚
        case 18...23, 0...4:
            return 3 // 晚上
        default:
            return 0 // 不限
        }
    }

    func findBestMatchedPoem(currentSeason: Int, currentWeather: Int, currentTime: Int) {
        let db = Firestore.firestore()
        
        // 鄰近度矩陣 (定義季節和時間的鄰近關係)
        let seasonProximityMatrix: [[Double]] = [
            [1.0, 1.0, 1.0, 1.0, 1.0],  // 不限
            [0.8, 1.0, 0.4, 0.2, 0.0],  // 春
            [0.8, 0.4, 1.0, 0.4, 0.2],  // 夏
            [0.8, 0.2, 0.4, 1.0, 0.2],  // 秋
            [0.8, 0.0, 0.2, 0.4, 1.0]   // 冬
        ]
        
        let timeProximityMatrix: [[Double]] = [
            [1.0, 1.0, 1.0, 1.0],
            [0.8, 1.0, 0.3, 0.0],
            [0.8, 0.3, 1.0, 0.3],
            [0.8, 0.0, 0.3, 1.0]
        ]
        
        let totalScore: Double = 100.0
        let perConditionScore = totalScore / 3.0 // 每個條件分配 1/3 的分數
        
        db.collection("poems").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching poems: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            var bestMatchingScore: Double = 0.0
            var bestMatchedPoem: [String: Any]?

            // 遍歷每一首詩
            for document in documents {
                let data = document.data()
                
                guard let poemSeason = data["season"] as? Int,
                      let poemWeather = data["weather"] as? Int,
                      let poemTime = data["time"] as? Int else {
                    continue
                }

                // 計算匹配度的總分
                var matchingScore: Double = 0.0
                
                // 匹配 "季節" - 使用鄰近度矩陣來給予分數
                matchingScore += seasonProximityMatrix[currentSeason][poemSeason] * perConditionScore
                
                // 匹配 "天氣"
                if currentWeather == poemWeather || poemWeather == 0 {
                    matchingScore += perConditionScore
                }
                
                // 匹配 "時間"
                if currentTime == poemTime || poemTime == 0 {
                    matchingScore += perConditionScore
                }
                
                // 如果這首詩的匹配度高於目前最高的匹配度，更新最佳匹配的詩
                if matchingScore > bestMatchingScore {
                    bestMatchingScore = matchingScore
                    bestMatchedPoem = data
                }
            }
            
            // 將匹配度轉換為百分比，並四捨五入到一位小數
            let matchingPercentage = round((bestMatchingScore / totalScore) * 1000) / 10.0

            if let bestPoem = bestMatchedPoem {
                print("最匹配的詩歌資料為: \(bestPoem)")
                print("匹配度為: \(matchingPercentage)%")
            } else {
                print("沒有找到符合條件的詩歌")
            }
        }
    }
}
