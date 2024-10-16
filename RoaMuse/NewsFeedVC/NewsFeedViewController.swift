import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import MJRefresh
import Kingfisher

class NewsFeedViewController: UIViewController {
    
    var notificationButton = UIButton()
    let postViewController = PostViewController()
    let db = Firestore.firestore()
    var postsArray = [[String: Any]]()
    let postsTableView = UITableView()
    let postButton = UIButton(type: .system)
    let postView = UIView()
    let avatarImageView = UIImageView()
    var likeCount = String()
    var bookmarkCount = String()
    var likeButtonIsSelected = Bool()
    var emptyStateLabel = UILabel()
    let bottomSheetView = UIView()
    let backgroundView = UIView()
    let sheetHeight: CGFloat = 250
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backButtonTitle = ""
        self.title = "動態"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, 
                .font: customFont
            ]
        }
        
        setupEmptyStateLabel()
        loadPostsForCurrentUserAndFollowing()
        loadAvatarImageForPostView()
        postsTableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        postsTableView.delegate = self
        postsTableView.dataSource = self
        view.backgroundColor = UIColor(resource: .backgroundGray)
        setupPostView()
        setupPostsTableView()
        setupRefreshControl()
        setupUserProfileImage()
        setupBottomSheet()
        
        postViewController.postButtonAction = { [weak self] in
            
            guard let self = self else { return }
            
            FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
                self.postsArray.insert(contentsOf: newPosts, at: 0)
                self.postsTableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        loadPostsForCurrentUserAndFollowing()
        setupNavigationBarStyle()
        notificationButton.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationButton.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        postsTableView.layoutIfNeeded()
    }
    
    private func setupNavigationBarStyle() {
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground() // 或根据需要设置
            navBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue,
                .font: customFont
            ]

            self.navigationItem.standardAppearance = navBarAppearance
            self.navigationItem.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    func setupUserProfileImage() {
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        
        notificationButton.layer.masksToBounds = true
        notificationButton.contentMode = .scaleAspectFill
        notificationButton.clipsToBounds = true
        
        navigationBar.addSubview(notificationButton)
        
        notificationButton.snp.makeConstraints { make in
            make.width.height.equalTo(25)
            make.trailing.equalTo(navigationBar.snp.trailing).offset(-16)
            make.bottom.equalTo(navigationBar.snp.bottom).offset(-15)
        }
        
        notificationButton.setImage(UIImage(named: "normal_heart"), for: .normal)
        notificationButton.addTarget(self, action: #selector(didTapNotificationButton), for: .touchUpInside)
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let userRef = FirebaseManager.shared.db.collection("users").document(currentUserId)
        
        userRef.addSnapshotListener { documentSnapshot, error in
            if let error = error { return }
            guard let document = documentSnapshot, document.exists, let data = document.data() else { return }
        }
    }
    
    @objc func didTapNotificationButton() {
        let notificationVC = NotificationViewController()
        navigationController?.pushViewController(notificationVC, animated: true)
    }
    
    func loadAvatarImageForPostView() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
            case .failure(let error):
                print("無法加載大頭貼: \(error.localizedDescription)")
            }
        }
    }
    
    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"), options: [
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ], completionHandler: { result in
            switch result {
            case .success(let value):
                print("圖片加載成功: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("圖片加載失敗: \(error.localizedDescription)")
            }
        })
    }
    
    func setupPostView() {
        
        postView.backgroundColor = .clear
        view.addSubview(postView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPostView))
        postView.addGestureRecognizer(tapGesture)
        postView.layer.cornerRadius = 30
        postView.backgroundColor = .white
        postView.layer.borderColor = UIColor.deepBlue.cgColor
        postView.layer.borderWidth = 2
        
        postView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(60)
        }
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.image = UIImage(named: "user-placeholder")
        postView.addSubview(avatarImageView)
        
        avatarImageView.snp.makeConstraints { make in
            make.centerY.equalTo(postView)
            make.leading.equalTo(postView).offset(6)
            make.width.height.equalTo(50) // 設置為圓形
        }
        
        let postLabel = UILabel()
        postLabel.text = "想說些什麼？"
        postLabel.textColor = .lightGray
        postLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        postView.addSubview(postLabel)
        
        postLabel.snp.makeConstraints { make in
            make.centerY.equalTo(postView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.trailing.equalTo(postView)
        }
    }
    
    // 點擊手勢的動作處理
    @objc func didTapPostView() {
        navigationController?.pushViewController(postViewController, animated: true)
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
        
        let impeachButton = createButton(title: "檢舉貼文")
        let blockButton = createButton(title: "封鎖用戶")
        let cancelButton = createButton(title: "取消", textColor: .red)
        
        let stackView = UIStackView(arrangedSubviews: [impeachButton, blockButton, cancelButton])
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
    
    @objc func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 0
        }
    }
    
    
    func setupPostButton() {
        
        view.addSubview(postButton)
        
        postButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
        }
        
        postButton.setTitle("發文", for: .normal)
        postButton.backgroundColor = .lightGray
        postButton.addTarget(self, action: #selector(didTapPostButton), for: .touchUpInside)
    }
    
    @objc func didTapPostButton() {
        
        navigationController?.pushViewController(postViewController, animated: true)
        
    }
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: postsTableView)
        
        if let indexPath = postsTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            
            guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
            saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
                if success {
                    
                    FirebaseManager.shared.loadPosts { posts in
                        let filteredPosts = posts.filter { post in
                            return post["id"] as? String == postId
                        }
                        if let matchedPost = filteredPosts.first,
                           let likesAccount = matchedPost["likesAccount"] as? [String] {
                            
                            self.likeCount = String(likesAccount.count)
                            self.likeButtonIsSelected = likesAccount.contains(userId)
                        } else {
                            
                            self.likeCount = "0"
                            self.likeButtonIsSelected = false
                        }
                    }
                    
                } else {
                    sender.isSelected.toggle()
                }
            }
        }
    }
    
    func saveLikeData(postId: String, userId: String, isLiked: Bool, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        postRef.getDocument { document, error in
            if let document = document, document.exists {
                guard let postOwnerId = document.data()?["userId"] as? String else {
                    completion(false)
                    return
                }
                
                if isLiked {
                    postRef.updateData([
                        "likesAccount": FieldValue.arrayUnion([userId])
                    ]) { error in
                        if let error = error {
                            completion(false)
                        } else {
                            completion(true)
                            
                            FirebaseManager.shared.fetchUserData(userId: userId) { result in
                                switch result {
                                case .success(let data):
                                let userName = data["userName"] as? String ?? ""
                                FirebaseManager.shared.saveNotification(
                                    to: postOwnerId,
                                    from: userId,
                                    postId: postId,
                                    type: 0,
                                    subType: nil, title: "你的日記被按讚了！",
                                    message: "\(userName) 按讚了你的日記",
                                    actionUrl: nil, priority: 0
                                ) { result in
                                    switch result {
                                    case .success:
                                        print("通知发送成功")
                                    case .failure(let error):
                                        print("通知发送失败: \(error.localizedDescription)")
                                    }
                                }
                                case .failure(let error):
                                    print("加載貼文發布者大頭貼失敗: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                } else {
                    postRef.updateData([
                        "likesAccount": FieldValue.arrayRemove([userId])
                    ]) { error in
                        if let error = error {
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
            }
        }
        
    }
        @objc func didTapCollectButton(_ sender: UIButton) {
            // 獲取按鈕點擊所在的行
            let point = sender.convert(CGPoint.zero, to: postsTableView)
            
            if let indexPath = postsTableView.indexPathForRow(at: point) {
                let postData = postsArray[indexPath.row]
                let postId = postData["id"] as? String ?? ""
                guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
                
                // 獲取當前的 bookmarkAccount
                var bookmarkAccount = postData["bookmarkAccount"] as? [String] ?? []
                
                if sender.isSelected {
                    // 如果按鈕已選中，取消收藏並移除 userId
                    bookmarkAccount.removeAll { $0 == userId }
                    
                    FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                        if success {
                            // 更新 Firestore 中的 bookmarkAccount 字段
                            self.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                                if let error = error {
                                    print("Failed to update bookmarkAccount: \(error)")
                                } else {
                                    // 成功取消收藏
                                }
                            }
                        } else {
                        }
                    }
                } else {
                    if !bookmarkAccount.contains(userId) {
                        bookmarkAccount.append(userId)
                    }
                    
                    FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                        if success {
                            // 更新 Firestore 中的 bookmarkAccount 字段
                            self.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                                if let error = error {
                                    print("Failed to update bookmarkAccount: \(error)")
                                } else {
                                    // 成功添加收藏
                                }
                            }
                        } else {
                            print("收藏失敗")
                        }
                    }
                }
                // 更新按鈕選中狀態
                sender.isSelected.toggle()
            }
        }
    }
    
extension NewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func setupPostsTableView() {
        view.addSubview(postsTableView)
        
        postsTableView.snp.makeConstraints { make in
            make.top.equalTo(postView.snp.bottom).offset(16)
            make.width.equalTo(view).multipliedBy(0.9)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
            make.centerX.equalTo(view)
        }
        
        postsTableView.rowHeight = UITableView.automaticDimension
        postsTableView.estimatedRowHeight = 300
        postsTableView.layer.borderColor = UIColor.deepBlue.cgColor
        postsTableView.layer.borderWidth = 2
        postsTableView.layer.cornerRadius = 20
        postsTableView.layer.masksToBounds = true
        postsTableView.allowsSelection = true
        postsTableView.backgroundColor = .white
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let offsetY = scrollView.contentOffset.y
//        let contentHeight = scrollView.contentSize.height
//        let scrollHeight = scrollView.frame.size.height
//        
//        guard contentHeight > scrollHeight else { return }
//        
//        let maxOffsetY = contentHeight - scrollHeight
//        let minOffsetY: CGFloat = 0
//        
//        if offsetY < minOffsetY {
//            scrollView.contentOffset.y = minOffsetY
//        } else if offsetY > maxOffsetY {
//            scrollView.contentOffset.y = maxOffsetY
//        }
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = postsTableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        let postData = postsArray[indexPath.row]
        
        guard let cell = cell else { return UITableViewCell() }
        
        cell.avatarImageView.image = nil
        cell.userNameLabel.text = nil
        cell.awardLabelView.updateTitle("初心者")
        cell.awardLabelView.backgroundColor = .systemGray
        
        guard let postOwnerId = postData["userId"] as? String else { return UITableViewCell() }
        cell.tag = indexPath.row
        cell.selectionStyle = .none
        cell.titleLabel.text = postData["title"] as? String
        cell.contentLabel.text = postData["content"] as? String
        cell.likeButton.addTarget(self, action: #selector(self.didTapLikeButton(_:)), for: .touchUpInside)
        cell.likeButton.isSelected = self.likeButtonIsSelected
        cell.likeCountLabel.text = self.likeCount
        cell.configurePhotoStackView(with: postData["photoUrls"] as? [String] ?? [])
        cell.configureMoreButton {
            self.showBottomSheet()
        }
        
        if let createdAtTimestamp = postData["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return cell }
        
        FirebaseManager.shared.isContentBookmarked(forUserId: currentUserId, id: postData["id"] as? String ?? "") { isBookmarked in
            DispatchQueue.main.async {
                cell.collectButton.isSelected = isBookmarked
            }
        }
        
        FirebaseManager.shared.fetchUserData(userId: postOwnerId) { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    // 使用 Kingfisher 加載圖片到 avatarImageView
                    DispatchQueue.main.async {
                        cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "user-placeholder"))
                    }
                }
                
                cell.userNameLabel.text = data["userName"] as? String
                
                FirebaseManager.shared.loadAwardTitle(forUserId: postOwnerId) { result in
                    DispatchQueue.main.async {
                        if cell.tag == indexPath.row {
                            switch result {
                            case .success(let (awardTitle, item)):
                                cell.awardLabelView.updateTitle(awardTitle)
                                AwardStyleManager.updateTitleContainerStyle(
                                    forTitle: awardTitle,
                                    item: item,
                                    titleContainerView: cell.awardLabelView,
                                    titleLabel: cell.awardLabelView.titleLabel,
                                    dropdownButton: nil
                                )
                            case .failure(let error):
                                print("獲取稱號失敗: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            case .failure(let error):
                print("加載貼文發佈者的頭像失敗: \(error.localizedDescription)")
            }
        }
        
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
                    cell.likeButton.isSelected = false // 如果沒有按讚，設置為未選中
                }
            }
        }
        
        cell.photoTappedHandler = { [weak self] index in
            guard let self = self else { return }
            let photoUrls = postData["photoUrls"] as? [String] ?? []
            self.showFullScreenImages(photoUrls: photoUrls, startingIndex: index)
        }
        
        cell.collectButton.addTarget(self, action: #selector(self.didTapCollectButton(_:)), for: .touchUpInside)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postsArray[indexPath.row]
        
        let articleVC = ArticleViewController()
        
        // 傳遞貼文的資料
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
                articleVC.tripId = post["tripId"] as? String ?? ""
                if let createdAtTimestamp = post["createdAt"] as? Timestamp {
                    let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                    articleVC.articleDate = createdAtString
                }
                articleVC.photoUrls = post["photoUrls"] as? [String] ?? []
                articleVC.authorId = post["userId"] as? String ?? ""
                articleVC.postId = post["id"] as? String ?? ""
                articleVC.bookmarkAccounts = post["bookmarkAccount"] as? [String] ?? []
                
                self.navigationController?.pushViewController(articleVC, animated: true)
            } else {
                print("未找到對應的 userName")
            }
        }
    }
}

extension NewsFeedViewController {
    
    private func loadPostsForCurrentUserAndFollowing() {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }

        // 從 Firestore 讀取當前用戶的資料，取得追蹤清單和封鎖清單
        let userRef = Firestore.firestore().collection("users").document(currentUserId)
        userRef.getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {
                print("無法獲取追蹤或封鎖清單")
                return
            }

            // 取得追蹤和封鎖清單
            let followingUsers = data["following"] as? [String] ?? []
            let blockedUsers = data["blockedUsers"] as? [String] ?? []

            var validUserIds = followingUsers
            validUserIds.append(currentUserId)

            FirebaseManager.shared.loadPosts { postsArray in
                let filteredPosts = postsArray.filter { post in
                    if let userId = post["userId"] as? String {
                        return validUserIds.contains(userId) && !blockedUsers.contains(userId)
                    }
                    return false
                }

                self.postsArray = filteredPosts
                DispatchQueue.main.async {
                    self.updateEmptyState()
                    self.postsTableView.reloadData()
                }
            }
        }
    }
    
    func getNewData() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

        db.collection("users").document(userId).addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            guard let document = documentSnapshot, let data = document.data() else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let followingArray = data["following"] as? [String] ?? []
            let blockedUsers = data["blockedUsers"] as? [String] ?? []

            var postsArray = [Dictionary<String, Any>]()
            let dispatchGroup = DispatchGroup()

            // 包含當前用戶的貼文
            let allUsersToFetch = followingArray + [userId]

            for userIdToFetch in allUsersToFetch {
                // 跳過封鎖的用戶
                if blockedUsers.contains(userIdToFetch) {
                    continue
                }

                dispatchGroup.enter()
                db.collection("posts").whereField("userId", isEqualTo: userIdToFetch)
                    .addSnapshotListener { querySnapshot, error in
                        if let error = error {
                            print("Error fetching posts: \(error.localizedDescription)")
                        } else if let snapshot = querySnapshot {
                            for document in snapshot.documents {
                                postsArray.append(document.data())
                            }
                        }
                        dispatchGroup.leave()
                    }
            }

            // 當所有資料都取得後，進行排序並更新 TableView
            dispatchGroup.notify(queue: .main) {
                self.postsArray = postsArray.sorted(by: { (post1, post2) -> Bool in
                    if let createdAt1 = post1["createdAt"] as? Timestamp,
                       let createdAt2 = post2["createdAt"] as? Timestamp {
                        return createdAt1.dateValue() > createdAt2.dateValue()
                    }
                    return false
                })

                // 更新 UI 並停止刷新動畫
                self.postsTableView.reloadData()
                self.updateEmptyState()
                self.postsTableView.mj_header?.endRefreshing()
            }
        }
    }

    func setupRefreshControl() {
        postsTableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.getNewData() // 在刷新時重新加載數據
        })
    }
    
    func setupEmptyStateLabel() {
        emptyStateLabel.text = "現在還沒有日記"
        emptyStateLabel.textColor = .lightGray
        emptyStateLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true  // 預設隱藏
        view.addSubview(emptyStateLabel)
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
    }
    
    func updateEmptyState() {
        let hasData = !postsArray.isEmpty
        emptyStateLabel.isHidden = hasData
        postsTableView.isHidden = !hasData
    }
    
    func showFullScreenImages(photoUrls: [String], startingIndex: Int) {
        let fullScreenVC = FullScreenImageViewController()
        let dispatchGroup = DispatchGroup()
        var images: [UIImage] = Array(repeating: UIImage(), count: photoUrls.count)

        // 使用 DispatchGroup 來確保所有圖片都載入完成後再進行顯示
        for (index, urlString) in photoUrls.enumerated() {
            guard let url = URL(string: urlString) else { continue }

            dispatchGroup.enter()
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { dispatchGroup.leave() }

                if let error = error {
                    print("圖片下載失敗: \(error.localizedDescription)")
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    images[index] = image
                }
            }.resume()
        }

        dispatchGroup.notify(queue: .main) {
            fullScreenVC.images = images
            fullScreenVC.startingIndex = startingIndex
            fullScreenVC.modalPresentationStyle = .fullScreen
            self.present(fullScreenVC, animated: true, completion: nil)
        }
    }
}
