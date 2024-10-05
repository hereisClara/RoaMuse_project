import UIKit
import SnapKit
import WeatherKit
import CoreLocation
import FirebaseFirestore
import MJRefresh
import Alamofire
import Kingfisher
import FirebaseAuth
import MapKit

class HomeViewController: UIViewController {
    
    private var isWaitingForLocation = false
    var bottomSheetManager: BottomSheetManager?
    private let locationManager = LocationManager()
    let locationService = LocationService()
    private let randomTripEntryButton = UIButton(type: .system)
    private let recommendRandomTripView = UIView()
    private let homeTableView = UITableView()
    private let popupView = PopUpView()
    let poemMatchingService = PoemMatchingService()
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    var likeCount = String()
    var bookmarkCount = String()
    var likeButtonIsSelected = Bool()
    var isUpdatingLikeStatus = false
    
    let bottomSheetView = UIView()
    let backgroundView = UIView()
    let sheetHeight: CGFloat = 250
    
    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    var matchingPlaces: [(keyword: String, place: Place)] = []
    var keywordToLineMap = [String: String]()
    var placePoemPairs = [PlacePoemPair]()
    
    var city: String = ""
    var districts: [String] = []
    let searchRadius: CLLocationDistance = 15000
    var trip: Trip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarItem.title = nil
        bottomSheetManager = BottomSheetManager(parentViewController: self, sheetHeight: 300)
        
        bottomSheetManager?.addActionButton(title: "隱藏貼文") {
        }
        
        bottomSheetManager?.addActionButton(title: "檢舉貼文", textColor: .red) {
            self.presentImpeachAlert()
        }
        
        bottomSheetManager?.addActionButton(title: "取消", textColor: .gray) {
            self.bottomSheetManager?.dismissBottomSheet()
        }
        
        locationManager.onAuthorizationChange = { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.isWaitingForLocation {
                    self.locationManager.requestLocation()
                }
            case .denied, .restricted:
                // 提示用户到设置中开启定位权限
                self.recommendRandomTripView.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            case .notDetermined:
                print("定位授权未决定")
            @unknown default:
                print("未知的授权状态")
            }
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        //        uploadTripsToFirebase()
        //        uploadPlaces()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "首頁"
        
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, // 修改顏色
                .font: customFont // 設置字體
            ]
        }
        
        view.backgroundColor = UIColor(resource: .backgroundGray)
        homeTableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        popupView.delegate = self
        observeLikeCountChanges()
        setupUI()
        setupTableView()
        setupPullToRefresh()
        //        uploadTripData()
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.homeTableView.reloadData()
        }
        //        setupLocationUpdates()
        setupUserProfileImage()
        setupChatButton()
        bottomSheetManager?.setupBottomSheet()
        
        view.addSubview(activityIndicator)
        setupActivityIndicator()
    }
    
    func setupActivityIndicator() {
        // 設置 activityIndicator 的佈局
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view) // 設置指示器在視圖的中央
        }
        
        // 初始化時隱藏
        activityIndicator.isHidden = true
    }
    
    @objc func showBottomSheetButtonTapped() {
        // 顯示彈窗
        bottomSheetManager?.showBottomSheet()
    }
    
    func setupUserProfileImage() {
        let avatarImageView = UIImageView()
        
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
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(-70)
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
                    avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                }
            } else {
                print("無法獲取照片 URL")
            }
        }
    }
    
//    MARK: chat
    func setupChatButton() {
        let chatButton = UIButton()
        chatButton.setImage(UIImage(systemName: "bubble.left.and.bubble.right"), for: .normal)
        self.view.addSubview(chatButton)
        
        chatButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.top.equalTo(self.view.safeAreaLayoutGuide)  // 調整頂部偏移量
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(-20)
        }
        
        chatButton.addTarget(self, action: #selector(toChatPage), for: .touchUpInside)
    }
    
    @objc func toChatPage() {
        
        if self.navigationController == nil {
            print("This view controller is not inside a navigation controller.")
        }
        
        let chatListVC = ChatListViewController()
        self.navigationController?.pushViewController(chatListVC, animated: true)
        
    }
    
    func observeLikeCountChanges() {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        recommendRandomTripView.layer.cornerRadius = 20
        recommendRandomTripView.layer.masksToBounds = true
        
        recommendRandomTripView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(120)
        }
        
        recommendRandomTripView.backgroundColor = .white
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recommendRandomTripView.addGestureRecognizer(tapGesture)
        
        // 在 recommendRandomTripView 裡面添加 UILabel
        let titleLabel = UILabel()
        titleLabel.text = "# 時令推薦"
        titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 26)
        titleLabel.textColor = UIColor(resource: .deepBlue)
        recommendRandomTripView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView).offset(20)
            make.leading.equalTo(recommendRandomTripView).offset(15)
        }
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "下雨的時候就是要......"
        descriptionLabel.font = UIFont(name: "NotoSerifHK-Medium", size: 18)
        descriptionLabel.textColor = UIColor(resource: .deepBlue)
        recommendRandomTripView.addSubview(descriptionLabel)
        
        poemMatchingService.getSeasonAndTimeText { [weak self] finalText in
            descriptionLabel.text = "\(finalText)的時候就是要......"
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
    }
    
    func updateRecommendViewWithSeasonAndTime() {
        poemMatchingService.getSeasonAndTimeText { [weak self] finalText in
            DispatchQueue.main.async {
                if let descriptionLabel = self?.recommendRandomTripView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                    descriptionLabel.text = finalText
                }
            }
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
        print("tap")
        recommendRandomTripView.isUserInteractionEnabled = false
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        
        locationManager.onLocationUpdate = { [weak self] location in
            print("onLocationUpdate called")
            guard let self = self else { return }
            self.locationManager.onLocationUpdate = nil
            
            self.processWithCurrentLocation(location)
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            recommendRandomTripView.isUserInteractionEnabled = true
            
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }
    
    func processWithCurrentLocation(_ currentLocation: CLLocation) {
        DispatchQueue.global(qos: .userInitiated).async {
            let currentSeason = self.poemMatchingService.getCurrentSeason()
            let currentTime = self.poemMatchingService.getCurrentTimeOfDay()
            self.poemMatchingService.findBestMatchedPoem(currentSeason: currentSeason, currentWeather: 0, currentTime: currentTime) { matchedPoem, matchedScore in
                if let matchedPoem = matchedPoem {
                    self.processPoemText(matchedPoem.content.joined(separator: "\n")) { keywords, keywordToLineMap in
                        self.keywordToLineMap = keywordToLineMap
                        self.generateTripFromKeywords(keywords, poem: matchedPoem, startingFrom: currentLocation) { trip in
                            if let trip = trip {
                                print("成功生成 trip：\(trip)")
                                let places = self.matchingPlaces.map { $0.place }
                                self.locationService.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: places) { totalTravelTime, routes in
                                    DispatchQueue.main.async {
                                        self.popupView.showPopup(on: self.view, with: trip, city: self.city, districts: self.districts)
                                        self.trip = trip
                                        self.recommendRandomTripView.isUserInteractionEnabled = true
                                        self.activityIndicator.stopAnimating()
                                        self.activityIndicator.isHidden = true
                                    }
                                }
                                
                                self.saveTripToFirebase(poem: matchedPoem) { savedTrip in
                                    if let savedTrip = savedTrip {
                                        print("行程已儲存至 Firebase，ID：\(savedTrip.id)")
                                    } else {
                                        print("行程儲存失敗")
                                    }
                                }
                            } else {
                                print("未能生成行程")
                                DispatchQueue.main.async {
                                    self.recommendRandomTripView.isUserInteractionEnabled = true
                                    self.activityIndicator.stopAnimating()
                                    self.activityIndicator.isHidden = true
                                }
                            }
                        }
                    }
                } else {
                    print("未找到匹配的诗歌")
                    DispatchQueue.main.async {
                        self.recommendRandomTripView.isUserInteractionEnabled = true
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                    }
                }
            }
        }
    }
    
    func processPoemText(_ inputText: String, completion: @escaping ([String], [String: String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard let model = try? poemLocationNLP3(configuration: .init()) else {
                print("NLP 模型加载失败")
                return
            }
            
            var allResults = [String]()
            var keywordToLineMap = [String: String]()
            for segment in textSegments {
                do {
                    let prediction = try model.prediction(text: segment)
                    let landscape = prediction.label
                    allResults.append(landscape)
                    keywordToLineMap[landscape] = segment
                } catch {
                    print("分析失败：\(error.localizedDescription)")
                }
            }
            
            // 返回不重复的关键字
            DispatchQueue.main.async {
                completion(Array(Set(allResults)), keywordToLineMap)
            }
        }
    }
    
}

extension HomeViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip
        tripDetailVC.keywordToLineMap = self.keywordToLineMap
        
        if let currentLocation = locationManager.currentLocation?.coordinate {
            let places = self.matchingPlaces.map { $0.place }
            LocationService.shared.calculateTotalRouteTimeAndDetails(from: currentLocation, places: places) { [weak self] totalTravelTime, routes in
                guard let self = self else { return }
                
                if let totalTravelTime = totalTravelTime, let routes = routes {
                    tripDetailVC.totalTravelTime = totalTravelTime
                    tripDetailVC.matchingPlaces = self.matchingPlaces
                    
                    // 創建導航指令數列
                    var nestedInstructions = [[String]]()
                    for route in routes {
                        var stepInstructions = [String]()
                        for step in route.steps {
                            stepInstructions.append(step.instructions)
                        }
                        nestedInstructions.append(stepInstructions)
                    }
                    tripDetailVC.nestedInstructions = nestedInstructions
                }
                
                self.navigationController?.pushViewController(tripDetailVC, animated: true)
            }
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        
        homeTableView.dataSource = self
        homeTableView.delegate = self
        
        homeTableView.rowHeight = UITableView.automaticDimension
        homeTableView.estimatedRowHeight = 400
        
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
        
        cell.configureMoreButton {
            self.bottomSheetManager?.showBottomSheet()
        }
        
        if let createdAtTimestamp = postData["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        if let postUserId = postData["userId"] as? String {
            FirebaseManager.shared.fetchUserData(userId: postUserId) { result in
                switch result {
                case .success(let data):
                    if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                        DispatchQueue.main.async {
                            cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                        }
                    }
                    
                    cell.userNameLabel.text = data["userName"] as? String
                    
                    FirebaseManager.shared.loadAwardTitle(forUserId: postUserId) { (result: Result<(String, Int), Error>) in
                        switch result {
                        case .success(let (awardTitle, item)):
                            let title = awardTitle
                            cell.awardLabelView.updateTitle(awardTitle)
                            DispatchQueue.main.async {
                                AwardStyleManager.updateTitleContainerStyle(
                                    forTitle: awardTitle,
                                    item: item,
                                    titleContainerView: cell.awardLabelView,
                                    titleLabel: cell.awardLabelView.titleLabel,
                                    dropdownButton: nil
                                )
                            }
                            
                        case .failure(let error):
                            print("獲取稱號失敗: \(error.localizedDescription)")
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
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
                articleVC.tripId = post["tripId"] as? String ?? ""
                articleVC.likeAccounts = post["likeAccount"] as? [String] ?? []
                articleVC.photoUrls = post["photoUrls"] as? [String] ?? []
                
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
                            }
                        }
                    } else {
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
                            }
                        }
                    } else {
                    }
                }
            }
        }
    }
    
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var foundValidPlace = false
        self.city = ""
        self.districts.removeAll()
        self.matchingPlaces.removeAll()
        
        for keyword in keywords {
            dispatchGroup.enter()
            self.processKeywordPlaces(keyword: keyword, currentLocation: currentLocation, dispatchGroup: dispatchGroup) { validPlaceFound in
                if validPlaceFound {
                    foundValidPlace = true
                }
            }
        }
        
        dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            if foundValidPlace, self.matchingPlaces.count >= 1 {
                FirebaseManager.shared.saveTripToFirebase(poem: poem, matchingPlaces: self.matchingPlaces) { trip in
                    DispatchQueue.main.async {
                        completion(trip)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

extension HomeViewController {
    
    func processKeywordPlaces(keyword: String, currentLocation: CLLocation, dispatchGroup: DispatchGroup, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
                let nearbyPlaces = places.filter { place in
                    let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                    let distance = currentLocation.distance(from: placeLocation)
                    return distance <= self.searchRadius
                }
                
                if !nearbyPlaces.isEmpty {
                    if let randomPlace = nearbyPlaces.randomElement() {
                        if !self.matchingPlaces.contains(where: { $0.place.id == randomPlace.id }) {
                            self.matchingPlaces.append((keyword: keyword, place: randomPlace))
                            
                            let placeLocation = CLLocation(latitude: randomPlace.latitude, longitude: randomPlace.longitude)
                            LocationService.shared.reverseGeocodeLocation(placeLocation) { (city, district) in
                                if let city = city, let district = district {
                                    if self.city.isEmpty {
                                        self.city = city
                                    }
                                    if !self.districts.contains(district) {
                                        self.districts.append(district)
                                    }
                                }
                                completion(true)
                                dispatchGroup.leave()
                            }
                        } else {
                            completion(true)
                            dispatchGroup.leave()
                        }
                    } else {
                        completion(false)
                        dispatchGroup.leave()
                    }
                } else {
                    PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                        if let newPlace = foundPlaces.first {
                            PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                                if let savedPlace = savedPlace {
                                    self.matchingPlaces.append((keyword: keyword, place: savedPlace))
                                    completion(true)
                                } else {
                                    completion(false)
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            completion(false)
                            DispatchQueue.main.async {
                                completion(true)
                                dispatchGroup.leave()
                            }
                        }
                    }
                }
            }
        }
    }
}

extension HomeViewController {
    
    func saveTripToFirebase(poem: Poem, completion: @escaping (Trip?) -> Void) {
        
        let keywordPlaceIds = self.matchingPlaces.map { ["keyword": $0.keyword, "placeId": $0.place.id] }
        
        let tripData: [String: Any] = [
            "poemId": poem.id,
            "placeIds": self.matchingPlaces.map { $0.place.id },
            "keywordPlaceIds": keywordPlaceIds,
            "tag": poem.tag
        ]
        
        FirebaseManager.shared.checkTripExists(tripData) { exists, existingTripId in
            if exists, let existingTripId = existingTripId {
                let existingTrip = Trip(
                    poemId: poem.id,
                    id: existingTripId,
                    placeIds: self.matchingPlaces.map { $0.place.id },
                    keywordPlaceIds: nil,
                    tag: poem.tag,
                    season: nil,
                    weather: nil,
                    startTime: nil
                )
                completion(existingTrip)
                
                self.getPoemPlacePair()
                self.saveSimplePlacePoemPairsToFirebase(tripId: existingTripId, simplePairs: self.placePoemPairs) { success in
                    if success {
                        print("Successfully saved placePoemPairs to Firebase.")
                    } else {
                        print("Failed to save placePoemPairs to Firebase.")
                    }
                    completion(existingTrip)
                }
                
            } else {
                let db = Firestore.firestore()
                var documentRef: DocumentReference? = nil
                documentRef = db.collection("trips").addDocument(data: tripData) { error in
                    if let error = error {
                        completion(nil)
                    } else {
                        guard let documentID = documentRef?.documentID else {
                            completion(nil)
                            return
                        }
                        // 更新 tripId
                        documentRef?.setData(["id": documentID], merge: true) { error in
                            if let error = error {
                                completion(nil)
                            } else {
                                let trip = Trip(
                                    poemId: poem.id,
                                    id: documentID,
                                    placeIds: self.matchingPlaces.map { $0.place.id },
                                    keywordPlaceIds: nil,
                                    tag: poem.tag,
                                    season: nil,
                                    weather: nil,
                                    startTime: nil
                                )
                                print("ready")
                                self.getPoemPlacePair()
                                print("          ", self.placePoemPairs)
                                self.saveSimplePlacePoemPairsToFirebase(tripId: documentID, simplePairs: self.placePoemPairs) { success in
                                    if success {
                                        print("Successfully saved placePoemPairs to Firebase.")
                                    } else {
                                        print("Failed to save placePoemPairs to Firebase.")
                                    }
                                    completion(trip)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getPoemPlacePair() {
        self.placePoemPairs.removeAll()
        for matchingPlace in matchingPlaces {
            let keyword = matchingPlace.keyword
            
            if let poemLine = keywordToLineMap[keyword] {
                let placePoemPair = PlacePoemPair(placeId: matchingPlace.place.id, poemLine: poemLine)
                placePoemPairs.append(placePoemPair)
            }
        }
    }
    
    func saveSimplePlacePoemPairsToFirebase(tripId: String, simplePairs: [PlacePoemPair], completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let tripRef = db.collection("trips").document(tripId)
        
        let placePoemData = simplePairs.map { pair in
            return [
                "placeId": pair.placeId,
                "poemLine": pair.poemLine
            ] as [String : Any]
        }
        
        tripRef.updateData([
            "placePoemPairs": placePoemData
        ]) { error in
            if let error = error {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func presentImpeachAlert() {
            let alertController = UIAlertController(title: "檢舉貼文", message: "你確定要檢舉這篇貼文嗎？", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "確定", style: .destructive) { _ in
                self.bottomSheetManager?.dismissBottomSheet()
            }
            alertController.addAction(confirmAction)
            
            present(alertController, animated: true, completion: nil)
        }
    
}
