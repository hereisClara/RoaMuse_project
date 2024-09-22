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
    let collectButton = UIButton(type: .system)
    let likeButton = UIButton(type: .system)
    let commentButton = UIButton(type: .system)
    let likeCountLabel = UILabel()
//    let bookmarkCountLabel = UILabel()
    let tripTitleLabel = UILabel()
    let commentTextField = UITextField()
    let sendButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTableView()
        tripTitleLabel.backgroundColor = .yellow  // 暫時設置背景顏色以檢查佈局
        tripTitleLabel.text = "~~~~~"
        checkBookmarkStatus()
        updateBookmarkData()
        loadComments()
        getTripData()
        
        setupCommentInput()
        updateLikesData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 檢查收藏狀態
        FirebaseManager.shared.isContentBookmarked(forUserId: authorId, id: postId) { [weak self] isBookmarked in
            guard let self = self else { return }
            self.collectButton.isSelected = isBookmarked
        }

        // 檢查按讚狀態
        FirebaseManager.shared.loadPosts { [weak self] posts in
            guard let self = self else { return }
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == self.postId
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                // 更新 likeCountLabel 和按鈕的選中狀態
                DispatchQueue.main.async {
                    self.likeCountLabel.text = String(likesAccount.count)
                    self.likeButton.isSelected = likesAccount.contains(self.authorId) // 檢查是否按過讚
                }
            } else {
                // 如果沒有找到相應的貼文，或者 likesAccount 為空
                DispatchQueue.main.async {
                    self.likeCountLabel.text = "0"
                    self.likeButton.isSelected = false
                }
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
        FirebaseManager.shared.isContentBookmarked(forUserId: authorId, id: postId) { [weak self] isBookmarked in
            guard let self = self else { return }
            self.collectButton.isSelected = isBookmarked
        }
    }
    
    // 按讚按鈕事件處理
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
            if success {
                print("按讚成功")
                self.updateLikesData()
            } else {
                print("取消按讚")
                sender.isSelected.toggle()
            }
        }
    }
    
    // 留言按鈕事件處理
    @objc func didTapCommentButton(_ sender: UIButton) {
        print("跳轉到留言區")
        // 可在此處跳轉到留言區
    }
    
    // 收藏按鈕事件處理
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        saveBookmarkData(postId: postId, userId: authorId, isBookmarked: sender.isSelected) { success in
            if success {
                print("收藏狀態更新成功")
                self.updateBookmarkData()
            } else {
                print("收藏狀態更新失敗")
                sender.isSelected.toggle() // 如果失敗，還原狀態
            }
        }
    }
    
    // 點擊送出按鈕
    @objc func didTapSendButton() {
        guard let commentContent = commentTextField.text, !commentContent.isEmpty else {
            print("留言內容不能為空")
            return
        }
        saveComment(userId: authorId, postId: postId, commentContent: commentContent) { success in
            if success {
                print("留言成功")
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
                print("留言保存成功")
                completion(true)
            }
        }
    }
    
    // 加載更新後的留言
    func loadComments() {
        // 模擬從 Firebase 加載留言
        Firestore.firestore().collection("posts").document(postId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let loadedComments = data["comments"] as? [[String: Any]] {
                self.comments = loadedComments
                self.tableView.reloadData()
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
            // 使用 arrayUnion 將 userId 添加到 posts 集合中的 bookmarkAccounts
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("收藏失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    // 同時更新 users 集合中的 bookmarkPost
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
            // 使用 arrayRemove 將 userId 從 posts 集合中的 bookmarkAccounts 中移除
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消收藏失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    // 從 users 集合中移除 bookmarkPost
                    userRef.updateData([
                        "bookmarkPost": FieldValue.arrayRemove([postId])
                    ]) { error in
                        if let error = error {
                            print("取消用戶收藏更新失敗: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("取消收藏成功，已更新資料")
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
                // 更新收藏數量
//                self.bookmarkCountLabel.text = String(bookmarkAccounts.count)
                print(bookmarkAccounts.count)
            } else {
                // 如果沒有找到相應的貼文，或者 bookmarkAccounts 為空
//                self.bookmarkCountLabel.text = "0"
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
                        self.tableView.tableHeaderView = headerView
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        
        let headerView = createHeaderView()
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = headerHeight
        headerView.frame = frame
        tableView.tableHeaderView = headerView
        
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.estimatedRowHeight = 120  // 預估行高
        tableView.rowHeight = UITableView.automaticDimension  // 自適應行高
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
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
        let titleLabel = UILabel()
        titleLabel.text = articleTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        let authorLabel = UILabel()
        authorLabel.text = "作者: \(articleAuthor)"
        authorLabel.font = UIFont.systemFont(ofSize: 16)
        authorLabel.numberOfLines = 0
        headerView.addSubview(authorLabel)
        
        let contentLabel = UILabel()
        contentLabel.text = articleContent
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width * 0.9
        headerView.addSubview(contentLabel)
        
        let dateLabel = UILabel()
        dateLabel.text = articleDate
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .gray
        dateLabel.numberOfLines = 0
        headerView.addSubview(dateLabel)
        
        // 設置 TripView
        let tripView = UIView()
        tripView.backgroundColor = .red
        headerView.addSubview(tripView)
        
        let tripTitleLabel = UILabel()
        tripView.addSubview(tripTitleLabel)
        
        // 使用 SnapKit 設置布局
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(headerView).offset(16)
            make.trailing.equalTo(headerView).offset(-16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(8)
            make.width.equalTo(headerView).multipliedBy(0.9)
            make.centerX.equalTo(headerView)
        }
        
        tripView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.width.equalTo(headerView).multipliedBy(0.9)
            make.height.equalTo(100)
            make.centerX.equalTo(headerView)
        }
        
        tripTitleLabel.snp.makeConstraints { make in
            make.center.equalTo(tripView)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(tripView.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
        }
        
        // 設置按讚按鈕
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .selected)
        likeButton.tintColor = UIColor.systemBlue
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        headerView.addSubview(likeButton)
        
        // 設置留言按鈕
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = UIColor.systemGreen
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        headerView.addSubview(commentButton)
        
        // 設置收藏按鈕
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor.systemPink
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        headerView.addSubview(collectButton)
        
        // 設置收藏和按讚數量標籤
//        bookmarkCountLabel.text = String(bookmarkAccounts.count)
//        bookmarkCountLabel.font = UIFont.systemFont(ofSize: 14)
//        headerView.addSubview(bookmarkCountLabel)
        
        likeCountLabel.text = "0"
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        headerView.addSubview(likeCountLabel)
        
        // 使用 SnapKit 設置按鈕和標籤的佈局
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.equalTo(headerView).offset(16)
            make.width.height.equalTo(30)
        }
        
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(70)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(70)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
            make.bottom.equalTo(headerView).offset(-16)
        }
        
//        bookmarkCountLabel.snp.makeConstraints { make in
//            make.leading.equalTo(collectButton.snp.trailing).offset(10)
//            make.centerY.equalTo(collectButton)
//        }
        
        likeCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(10)
            make.centerY.equalTo(likeButton)
        }
    }



    func setupActionButtons(in headerView: UIView) {
        // 設置按讚按鈕
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .selected)
        likeButton.tintColor = UIColor.systemBlue
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        
        // 設置留言按鈕
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = UIColor.systemGreen
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        
        // 設置收藏按鈕
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor.systemPink
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        
        // 設置收藏和按讚數量標籤
//        bookmarkCountLabel.text = String(bookmarkAccounts.count)
//        bookmarkCountLabel.font = UIFont.systemFont(ofSize: 14)
        
        likeCountLabel.text = "0"
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        
    }

    
    // UITableViewDataSource - 設定 cell 的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count  // 返回留言數量
    }
    
    // UITableViewDataSource - 設定每個 cell 的樣式
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        
        if comments.count > 0 {
            let comment = comments[indexPath.row]
            print(comment)
            FirebaseManager.shared.fetchUserNameByUserId(userId: comment["userId"] as? String ?? "") { username in
                if let username = username {
                    cell.usernameLabel.text = username
                    cell.contentLabel.text = comment["content"] as? String
                    if let createdAtTimestamp = comment["createdAt"] as? Timestamp {
                        let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                        cell.createdAtLabel.text = createdAtString
                    }
                }
            }
        }
        return cell
    }
    // UITableViewDelegate - 設定自動調整行高
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}




