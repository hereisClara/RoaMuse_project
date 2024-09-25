import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class ArticleViewController: UIViewController {
    
    var authorId = String()
    var postId = String()
    var tripId = String()
    var bookmarkAccounts = [String]()
    var likeAccounts = [String]()
    let tableView = UITableView()
    
    var articleTitle = String()
    var articleAuthor = String()
    var articleContent = String()
    var articleDate = String()
    var comments = [[String: Any]]()
    
    var isBookmarked = false
    let collectButton = UIButton()
    let likeButton = UIButton()
    let commentButton = UIButton()
    let likeCountLabel = UILabel()
    let tripTitleLabel = UILabel()
    let commentTextField = UITextField()
    let sendButton = UIButton(type: .system)
    let tripView = UIView()
    let avatarImageView = UIImageView()
    var isUpdatingLikeStatus = false
    
    let titleLabel = UILabel()
    let authorLabel = UILabel()
    let contentLabel = UILabel()
    let dateLabel = UILabel()
    
    var trip: Trip?
    
    private let popupView = PopUpView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        self.navigationItem.largeTitleDisplayMode = .never
        
        observeLikeCountChanges()
        
        popupView.delegate = self
        setupTableView()
        checkBookmarkStatus()
        updateBookmarkData()
        
        getTripData()
        
        setupCommentInput()
        updateLikesData()
        setupTripViewAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getTripData()
        observeLikeCountChanges()
        checkBookmarkStatus()
        loadComments()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width * 0.5
        avatarImageView.layer.masksToBounds = true
    }
    
    func observeLikeCountChanges() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId")
            return
        }
        
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        postRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // 如果正在更新按讚狀態，暫停監聽器的更新
            if self.isUpdatingLikeStatus {
                return
            }
            
            if let error = error {
                print("監聽按讚數量變化時出錯: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(), let likesAccount = data["likesAccount"] as? [String] else {
                print("無法加載按讚數據")
                return
            }
            
            DispatchQueue.main.async {
                self.likeCountLabel.text = String(likesAccount.count)
                self.likeButton.isSelected = likesAccount.contains(userId)
            }
        }
    }

    func setupCommentInput() {
        commentTextField.placeholder = "輸入留言..."
        commentTextField.borderStyle = .roundedRect
        view.addSubview(commentTextField)
        
        sendButton.setTitle("送出", for: .normal)
        sendButton.addTarget(self, action: #selector(didTapSendButton), for: .touchUpInside)
        view.addSubview(sendButton)
        
        commentTextField.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(40)
        }
        
        sendButton.snp.makeConstraints { make in
            make.leading.equalTo(commentTextField.snp.trailing).offset(10)
            make.trailing.equalTo(view).offset(-16)
            make.bottom.equalTo(commentTextField)
            make.height.equalTo(commentTextField)
            make.width.equalTo(80)
        }
    }
    
    // 檢查文章是否已被收藏，並更新收藏按鈕狀態
    func checkBookmarkStatus() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        FirebaseManager.shared.isContentBookmarked(forUserId: userId, id: postId) { [weak self] isBookmarked in
            guard let self = self else { return }
            self.collectButton.isSelected = isBookmarked
        }
    }

    
    // 按讚按鈕事件處理
    @objc func didTapLikeButton(_ sender: UIButton) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        // 暫停監聽
        isUpdatingLikeStatus = true
        
        sender.isSelected.toggle() // 切換按鈕狀態
        
        saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
            if success {
                self.updateLikesData()
            } else {
                print("取消按讚失敗")
                sender.isSelected.toggle() // 還原按鈕狀態
            }
            
            // 完成更新後恢復監聽
            self.isUpdatingLikeStatus = false
        }
    }
    
    // 留言按鈕事件處理
    @objc func didTapCommentButton(_ sender: UIButton) {
        scrollToFirstComment()
    }
    
    // 收藏按鈕事件處理
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        saveBookmarkData(postId: postId, userId: authorId, isBookmarked: sender.isSelected) { success in
            if success {
                self.updateBookmarkData()
            } else {
                sender.isSelected.toggle() // 如果失敗，還原狀態
            }
        }
    }
    
    // 點擊送出按鈕
    @objc func didTapSendButton() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let commentContent = commentTextField.text, !commentContent.isEmpty else {
            print("留言內容不能為空")
            return
        }
        saveComment(userId: userId, postId: postId, commentContent: commentContent) { success in
            if success {
                self.loadComments()
                self.commentTextField.text = "" // 清空輸入框
            } else {
                print("留言失敗")
            }
        }
    }

    
    // 保存留言
    func saveComment(userId: String, postId: String, commentContent: String, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        let commentId = UUID().uuidString
        let commentData: [String: Any] = [
            "id": commentId,
            "userId": userId,
            "content": commentContent,
            "createdAt": Timestamp(date: Date())
        ]
        
        postRef.updateData([
            "comments": FieldValue.arrayUnion([commentData])
        ]) { error in
            if let error = error {
                print("保存留言失敗: \(error.localizedDescription)")
                completion(false)
            } else {
//                print("留言保存成功")
                completion(true)
            }
        }
    }
    
    // MARK: 加載更新後的留言
    func loadComments() {
        print("Loading comments...")
        
        Firestore.firestore().collection("posts").document(postId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading comments: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(), let loadedComments = data["comments"] as? [[String: Any]] else {
                print("No comments found.")
                return
            }
            
            // 將每個 comment 進行解碼處理，儲存在 comments 數組中
            var decodedComments: [[String: Any]] = []
            
            let dispatchGroup = DispatchGroup()  // 使用 DispatchGroup 確保所有的異步加載完成後再繼續
            
            for var comment in loadedComments {
                dispatchGroup.enter()
                
                // 先解碼 userId 對應的 username
                let userId = comment["userId"] as? String ?? ""
                FirebaseManager.shared.fetchUserNameByUserId(userId: userId) { username in
                    comment["username"] = username  // 將取得的 username 存入 comment 中
                    
                    // 同時解碼用戶大頭貼的 URL
                    FirebaseManager.shared.fetchUserData(userId: userId) { result in
                        switch result {
                        case .success(let data):
                            if let photoUrlString = data["photo"] as? String {
                                comment["avatarUrl"] = photoUrlString  // 存入大頭貼 URL
                            }
                        case .failure(let error):
                            print("Error loading user avatar: \(error.localizedDescription)")
                        }
                        
                        decodedComments.append(comment)
                        dispatchGroup.leave()  // 當這條 comment 的解碼完成後，leave group
                    }
                }
            }
            
            // 當所有的資料解碼完成後，更新 UI
            dispatchGroup.notify(queue: .main) {
                self.comments = decodedComments  // 將解碼後的資料賦值給 self.comments
                print("Decoded comments: \(self.comments)")  // 打印解碼後的資料
                
                // 設定 tableView 並重新整理 UI
                self.setupTableView()
                self.tableView.reloadData()
            }
        }
    }

    func saveLikeData(postId: String, userId: String, isLiked: Bool, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        if isLiked {
            postRef.updateData([
                "likesAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("按讚失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self.updateLikesData()
                    completion(true)
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
                    self.updateLikesData()
                    completion(true)
                }
            }
        }
    }


    
    func updateLikesData() {
        
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == self.postId
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                // 更新 likeCountLabel
                self.likeCountLabel.text = String(likesAccount.count)
                self.likeButton.isSelected = likesAccount.contains(self.authorId)
            } else {
                // 如果沒有找到相應的貼文，或者 likesAccount 為空
                self.likeCountLabel.text = "0"
                self.likeButton.isSelected = false
            }
        }
    }
    
    func saveBookmarkData(postId: String, userId: String, isBookmarked: Bool, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        if isBookmarked {
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("收藏失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    userRef.updateData([
                        "bookmarkPost": FieldValue.arrayUnion([postId])
                    ]) { error in
                        if let error = error {
                            print("用戶收藏更新失敗: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("收藏成功，已更新資料")
                            completion(true)
                        }
                    }
                }
            }
        } else {
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消收藏失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    userRef.updateData([
                        "bookmarkPost": FieldValue.arrayRemove([postId])
                    ]) { error in
                        if let error = error {
                            print("取消用戶收藏更新失敗: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
            }
        }
    }

    
    func updateBookmarkData() {
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == self.postId
            }
            
            if let matchedPost = filteredPosts.first,
               let bookmarkAccounts = matchedPost["bookmarkAccount"] as? [String] {
                
                DispatchQueue.main.async {
                    self.collectButton.isSelected = bookmarkAccounts.contains(self.authorId)
                }
                
            } else {
                // 如果沒有找到相應的貼文，或者 bookmarkAccounts 為空
                DispatchQueue.main.async {
                    self.collectButton.isSelected = false
                }
            }
        }
    }
    
    
    func getTripData() {
        FirebaseManager.shared.loadAllTrips { trips in
            let filteredTrips = trips.filter { trip in
                return trip.id == self.tripId
            }
            if let matchedTrip = filteredTrips.first {
                DispatchQueue.main.async {
                    self.tripTitleLabel.text = matchedTrip.poem.title
                    print(self.tripTitleLabel.text ?? "No title")  // 確認是否已經更新文本
                    
                    // 手動更新表頭
                    if let headerView = self.tableView.tableHeaderView {
                        // 更新表頭佈局
                        headerView.setNeedsLayout()
                        headerView.layoutIfNeeded()
                        
                        // 計算並更新表頭高度
                        let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                        var frame = headerView.frame
                        frame.size.height = headerHeight
                        headerView.frame = frame
                        
                        // 設置更新後的表頭
                        self.tableView.tableHeaderView = headerView
                    }
                    // 確保 UI 重新加載
                    self.tableView.reloadData()
                }
            }
        }
    }
}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func setupTableView() {
        print("撐開")
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let headerView = createHeaderView()
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = headerHeight
        headerView.frame = frame
        tableView.tableHeaderView = headerView
        tableView.layoutIfNeeded()
        
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        
        tableView.estimatedRowHeight = 180  // 預估行高
        tableView.rowHeight = UITableView.automaticDimension  // 自適應行高
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-60)
        }
        
    }
    
    // 創建表頭視圖 (header)
    func createHeaderView() -> UIView {
        let headerView = UIView()
        
        setupHeaderView(in: headerView)
        
        // 設置按讚和收藏等按鈕
        setupActionButtons(in: headerView)
        
        return headerView
    }
    
    func setupHeaderView(in headerView: UIView) {
        // 設置文章標題、作者、內容和日期
        titleLabel.text = articleTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        authorLabel.text = "作者: \(articleAuthor)"
        authorLabel.font = UIFont.systemFont(ofSize: 16)
        authorLabel.numberOfLines = 0
        headerView.addSubview(authorLabel)
        
        contentLabel.text = articleContent
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width * 0.9
        headerView.addSubview(contentLabel)

        dateLabel.text = articleDate
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .gray
        dateLabel.numberOfLines = 0
        headerView.addSubview(dateLabel)
        
        setupAvatar()
        headerView.addSubview(avatarImageView)
        
        // 設置 TripView
        tripView.backgroundColor = .deepBlue
        tripView.layer.cornerRadius = 20
        headerView.addSubview(tripView)
        
        tripTitleLabel.textColor = .white
        tripTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        tripView.addSubview(tripTitleLabel)
        
        // 使用 SnapKit 設置布局
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.trailing.equalTo(headerView).offset(-16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.trailing.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(8)
            make.width.equalTo(headerView).multipliedBy(0.9)
            make.centerX.equalTo(headerView)
        }
        
        tripView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.width.equalTo(headerView).multipliedBy(0.9)
            make.height.equalTo(60)
            make.centerX.equalTo(headerView)
        }
        
        tripTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(tripView)
            make.leading.equalTo(tripView).offset(16)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(tripView.snp.bottom).offset(12)
            make.leading.equalTo(avatarImageView)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(headerView).offset(15)
            make.width.height.equalTo(50)
        }
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        // 設置按讚按鈕
        likeButton.setImage(UIImage(named: "normal_heart"), for: .normal)
        likeButton.setImage(UIImage(named: "selected_heart"), for: .selected)
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        headerView.addSubview(likeButton)
        
        // 設置留言按鈕
        commentButton.setImage(UIImage(named: "normal_comment"), for: .normal)
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        headerView.addSubview(commentButton)
        
        // 設置收藏按鈕
        collectButton.setImage(UIImage(named: "normal_bookmark"), for: .normal)
        collectButton.setImage(UIImage(named: "selected_bookmark"), for: .selected)
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        headerView.addSubview(collectButton)
        
        likeCountLabel.text = "0"
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        headerView.addSubview(likeCountLabel)
        
        // 使用 SnapKit 設置按鈕和標籤的佈局
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.equalTo(headerView).offset(20)
            make.width.height.equalTo(25)
        }
        
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(70)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(25)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(70)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(25)
            make.bottom.equalTo(headerView).offset(-16)
        }
        
        likeCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(10)
            make.centerY.equalTo(likeButton)
        }
    }
    
    func setupActionButtons(in headerView: UIView) {
        // 設置按讚按鈕
        
        likeButton.tintColor = UIColor.systemBlue
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        
        // 設置留言按鈕
        commentButton.tintColor = UIColor.systemGreen
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        
        // 設置收藏按鈕
        collectButton.tintColor = UIColor.systemPink
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        
        likeCountLabel.text = "0"
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setupTripViewAction() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openPopupView))
        tripView.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func openPopupView() {
        
        getTripDataById()
        
    }
    
    func getTripDataById() {
        let db = Firestore.firestore()
        
        // 根據 tripId 查詢對應的行程
        db.collection("trips").whereField("id", isEqualTo: self.tripId).getDocuments { snapshot, error in
            if let error = error {
                print("查詢行程時發生錯誤: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents, let document = documents.first {
                // 將查詢結果轉換為 Trip 對象
                let data = document.data()
                if let poemData = data["poem"] as? [String: Any],
                   let title = poemData["title"] as? String,
                   let poetry = poemData["poetry"] as? String,
                   let original = poemData["original"] as? [String],
                   let translation = poemData["translation"] as? [String],
                   let secretTexts = poemData["secretTexts"] as? [String],
                   let situationText = poemData["situationText"] as? [String],
                   let placesData = data["places"] as? [[String: Any]],
                   let tag = data["tag"] as? Int,
                   let season = data["season"] as? Int,
                   let weather = data["weather"] as? Int,
                   let startTime = data["startTime"] as? Int {
                    
                    // 解析地點資料
                    let places = placesData.compactMap { placeDict -> PlaceId? in
                        if let placeId = placeDict["id"] as? String {
                            return PlaceId(id: placeId)
                        }
                        return nil
                    }
                    
                    // 初始化 Poem 和 Trip 對象
                    let poem = Poem(
                        title: title,
                        poetry: poetry,
                        original: original,
                        translation: translation,
                        secretTexts: secretTexts,
                        situationText: situationText
                    )
                    
                    self.trip = Trip(
                        poem: poem,
                        id: self.tripId,
                        places: places,
                        tag: tag,
                        season: season,
                        weather: weather,
                        startTime: startTime
                    )
                    
                    // 顯示 popup
                    DispatchQueue.main.async {
                        self.popupView.showPopup(on: self.view, with: self.trip!)
                    }
                } else {
                    print("未找到對應的行程資料")
                }
            } else {
                print("未找到對應的行程")
            }
        }
    }

    func setupAvatar() {
        // 使用 `authorId` 加載貼文作者的頭像
        FirebaseManager.shared.fetchUserData(userId: authorId) { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    DispatchQueue.main.async {
                        // 使用 Kingfisher 加载图片到 avatarImageView
                        self.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                } else {
                    print("無法加載貼文作者的照片")
                }
            case .failure(let error):
                print("加載貼文作者的資料失敗: \(error.localizedDescription)")
            }
        }
        
        // 為頭像添加點擊手勢
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAvatar))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    @objc func didTapAvatar() {
        // 創建 ProfileViewController 的實例
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = authorId // 傳遞作者的 userId

        // 將頁面推入導航堆疊
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }

    
    func scrollToFirstComment() {
        let firstCommentIndexPath = IndexPath(row: 0, section: 0)
        if comments.count > 0 {
            tableView.scrollToRow(at: firstCommentIndexPath, at: .top, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 延遲一點時間等待滾動完成，然後讓 textField 成為第一響應者
                self.commentTextField.becomeFirstResponder()
            }
        } else {
            // 如果沒有留言，直接讓 textField 成為第一響應者
            commentTextField.becomeFirstResponder()
        }
    }
    
    // UITableViewDataSource - 設定 cell 的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count  // 返回留言數量
    }
    
    // MARK: cell for row at
    // UITableViewDataSource - 設定 cell 的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        if comments.count > 0 {
            let comment = comments[indexPath.row]
            
            // 設定留言內容
            cell.contentLabel.text = comment["content"] as? String
            
            // 設定用戶名
            cell.usernameLabel.text = comment["username"] as? String
            
            // 設定時間
            if let createdAtTimestamp = comment["createdAt"] as? Timestamp {
                let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                cell.createdAtLabel.text = createdAtString
            }
            
            // 設定大頭貼
            if let avatarUrlString = comment["avatarUrl"] as? String, let avatarUrl = URL(string: avatarUrlString) {
                DispatchQueue.main.async {
                    cell.avatarImageView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "placeholder"))
                }
            }
        }
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }

}

extension ArticleViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        
        guard let trip = self.trip else {
                    print("Error: Trip is nil!")
                    return
                }
        
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
    
}
