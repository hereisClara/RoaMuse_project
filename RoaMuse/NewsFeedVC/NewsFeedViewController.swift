import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import MJRefresh
import Kingfisher

class NewsFeedViewController: UIViewController {
    
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
    
    let bottomSheetView = UIView()
    let backgroundView = UIView() // 半透明背景
    let sheetHeight: CGFloat = 250 // 選單高度
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "動態"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, // 修改顏色
                .font: customFont // 設置字體
            ]
        }
        loadAvatarImageForPostView()
        postsTableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        postsTableView.delegate = self
        postsTableView.dataSource = self
        view.backgroundColor = UIColor(resource: .backgroundGray)
        setupPostView()
        setupPostsTableView()
        setupRefreshControl()
        setupBottomSheet()
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.postsTableView.reloadData()
        }
        
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
        
        FirebaseManager.shared.loadPosts { [weak self] postsArray in
            self?.postsArray = postsArray
            DispatchQueue.main.async {
                self?.postsTableView.reloadData() // 確保 UI 更新
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        postsTableView.layoutIfNeeded()
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
    
    // 加載圖片的通用方法
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
        // 建立一個容器 View 來取代原先的 postButton
        
        postView.backgroundColor = .clear
        view.addSubview(postView)
        
        // 設置點擊手勢
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
            make.height.equalTo(60) // 設置高度
        }
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.image = UIImage(named: "user-placeholder") // 可以替換成實際的 avatar 圖片
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
        
        // 在選單視圖內部添加按鈕
//        let saveButton = createButton(title: "隱藏貼文")
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
                            // 更新 likeCountLabel
                            self.likeCount = String(likesAccount.count)
                            self.likeButtonIsSelected = likesAccount.contains(userId)
                        } else {
                            // 如果沒有找到相應的貼文，或者 likesAccount 為空
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
                    print("未能找到貼文擁有者")
                    completion(false)
                    return
                }
                
                if isLiked {
                    postRef.updateData([
                        "likesAccount": FieldValue.arrayUnion([userId])
                    ]) { error in
                        if let error = error {
                            print("按讚失敗: \(error.localizedDescription)")
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
                            print("取消按讚失敗: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            //                    print("取消按讚成功，已更新資料")
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
                            print("取消收藏失敗")
                        }
                    }
                } else {
                    // 如果按鈕未選中，進行收藏並加入 userId
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
        postsTableView.estimatedRowHeight = 250
        postsTableView.layer.borderColor = UIColor.deepBlue.cgColor
        postsTableView.layer.borderWidth = 2
        postsTableView.layer.cornerRadius = 20
        postsTableView.layer.masksToBounds = true
        postsTableView.allowsSelection = true
        postsTableView.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = postsTableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        let postData = postsArray[indexPath.row]
        
        guard let cell = cell else { return UITableViewCell() }
        
        // 獲取貼文發佈者的 userId
        guard let postOwnerId = postData["userId"] as? String else { return UITableViewCell() }
        
        cell.selectionStyle = .none
        cell.titleLabel.text = postData["title"] as? String
        cell.contentLabel.text = postData["content"] as? String
        cell.likeButton.addTarget(self, action: #selector(self.didTapLikeButton(_:)), for: .touchUpInside)
        cell.likeButton.isSelected = self.likeButtonIsSelected
        cell.likeCountLabel.text = self.likeCount
        cell.configurePhotoStackView(with: postData["photoUrls"] as? [String] ?? [])
        cell.configureMoreButton {
            self.showBottomSheet()  // 顯示彈窗
        }
        
        if let createdAtTimestamp = postData["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        // 檢查該貼文是否已被當前用戶收藏
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return cell }
        
        FirebaseManager.shared.isContentBookmarked(forUserId: currentUserId, id: postData["id"] as? String ?? "") { isBookmarked in
            DispatchQueue.main.async {
                cell.collectButton.isSelected = isBookmarked
            }
        }
        
        // 獲取貼文發佈者的資料（頭像）
        FirebaseManager.shared.fetchUserData(userId: postOwnerId) { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    // 使用 Kingfisher 加載圖片到 avatarImageView
                    DispatchQueue.main.async {
                        cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                }
                
                cell.userNameLabel.text = data["userName"] as? String
                
                FirebaseManager.shared.loadAwardTitle(forUserId: postOwnerId) { (result: Result<(String, Int), Error>) in
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
                print("加載貼文發佈者的頭像失敗: \(error.localizedDescription)")
            }
        }
        
        // 加載貼文的按讚數據
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == postData["id"] as? String
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                // 更新 likeCountLabel 和按鈕的選中狀態
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
    
    func getNewData() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        
        // 首先，取得使用者的 following 名單
        db.collection("users").document(userId).addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            guard let document = documentSnapshot, let data = document.data() else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // 從用戶資料中提取 following 名單
            if let followingArray = data["following"] as? [String] {
                var postsArray = [Dictionary<String, Any>]()
                let dispatchGroup = DispatchGroup()  // 使用 DispatchGroup 來同步多個資料庫請求

                for followingUserId in followingArray {
                    dispatchGroup.enter()  // 進入一個異步請求
                    
                    // 為每個 following 的使用者加上貼文監聽
                    db.collection("posts").whereField("userId", isEqualTo: followingUserId).addSnapshotListener { querySnapshot, error in
                        if let error = error {
                            print("Error fetching posts: \(error.localizedDescription)")
                        } else {
                            for document in querySnapshot!.documents {
                                postsArray.append(document.data())
                            }
                        }
                        dispatchGroup.leave()  // 當前請求完成
                    }
                }
                
                // 當所有請求完成後，進行排序並更新 TableView
                dispatchGroup.notify(queue: .main) {
                    // 依照貼文創建時間進行排序
                    self.postsArray = postsArray.sorted(by: { (post1, post2) -> Bool in
                        if let createdAt1 = post1["createdAt"] as? Timestamp, let createdAt2 = post2["createdAt"] as? Timestamp {
                            return createdAt1.dateValue() > createdAt2.dateValue()
                        }
                        return false
                    })
                    
                    // 更新 UI
                    self.postsTableView.reloadData()
                    self.postsTableView.mj_header?.endRefreshing()
                }
            }
        }
    }

    
    func setupRefreshControl() {
        // 使用 MJRefreshNormalHeader，當下拉時觸發的刷新動作
        postsTableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.getNewData() // 在刷新時重新加載數據
        })
    }
}
