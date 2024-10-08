import Foundation
import Kingfisher
import UIKit
import SnapKit
import FirebaseFirestore

class ArticleViewController: UIViewController {
    
    var authorId = String()
    var postId = String()
    var tripId = String()
    var poemId = String()
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
    let awardLabelView = AwardLabelView(title: "初心者")
    let titleLabel = UILabel()
    let authorLabel = UILabel()
    let contentLabel = UILabel()
    let dateLabel = UILabel()
    var photoUrls = [String]()
    let photoContainerView = UIView()
    
    var poemTitle = String()
    var trip: Trip?
    var isScrolledToFirstComment = false
    
    private let popupView = PopUpView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = UIColor.deepBlue
        tabBarController?.tabBar.isHidden = true
        self.navigationItem.largeTitleDisplayMode = .never
        getTripData()
        observeLikeCountChanges()
        
        popupView.delegate = self
        setupTableView()
        setupPhotos()
        updateHeaderViewLayout()
        checkBookmarkStatus()
        updateBookmarkData()
        
        setupCommentInput()
        updateLikesData()
        setupTripViewAction()
        
        FirebaseManager.shared.loadAwardTitle(forUserId: authorId) { (result: Result<(String, Int), Error>) in
            switch result {
            case .success(let (awardTitle, item)):
                let title = awardTitle
                self.awardLabelView.updateTitle(awardTitle)
                DispatchQueue.main.async {
                    AwardStyleManager.updateTitleContainerStyle(
                        forTitle: awardTitle,
                        item: item,
                        titleContainerView: self.awardLabelView,
                        titleLabel: self.awardLabelView.titleLabel,
                        dropdownButton: nil
                    )
                }
                
            case .failure(let error):
                print("獲取稱號失敗: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let tabBarController = self.tabBarController {
            tabBarController.tabBar.isHidden = true
        } else {
        }
        
        observeLikeCountChanges()
        checkBookmarkStatus()
        loadComments()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width * 0.5
        avatarImageView.layer.masksToBounds = true
    }
    
    func observeLikeCountChanges() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        postRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if self.isUpdatingLikeStatus { return }
            
            if let error = error { return }
            
            guard let data = snapshot?.data(), let likesAccount = data["likesAccount"] as? [String] else { return }
            
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
    
    func checkBookmarkStatus() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        FirebaseManager.shared.isContentBookmarked(forUserId: userId, id: postId) { [weak self] isBookmarked in
            guard let self = self else { return }
            self.collectButton.isSelected = isBookmarked
        }
    }
    
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
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func loadComments() {
        Firestore.firestore().collection("posts").document(postId).getDocument { snapshot, error in
            if let error = error { return }
            
            guard let data = snapshot?.data(), let loadedComments = data["comments"] as? [[String: Any]] else {
                return
            }
            
            var decodedComments: [[String: Any]] = []
            let dispatchGroup = DispatchGroup()
            
            for var comment in loadedComments {
                dispatchGroup.enter()
                
                let userId = comment["userId"] as? String ?? ""
                FirebaseManager.shared.fetchUserNameByUserId(userId: userId) { username in
                    comment["username"] = username
                    
                    FirebaseManager.shared.fetchUserData(userId: userId) { result in
                        switch result {
                        case .success(let data):
                            if let photoUrlString = data["photo"] as? String {
                                comment["avatarUrl"] = photoUrlString
                            }
                        case .failure(let error):
                            print("Error loading user avatar: \(error.localizedDescription)")
                        }
                        
                        decodedComments.append(comment)
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // 對 comments 根據 createdAt 進行由舊到新的排序
                self.comments = decodedComments.sorted {
                    let date1 = ($0["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let date2 = ($1["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    return date1 < date2
                }
                
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
                    
                    FirebaseManager.shared.fetchUserData(userId: userId) { result in
                        switch result {
                        case .success(let data):
                            let userName = data["userName"] as? String ?? ""
                            FirebaseManager.shared.saveNotification(
                                to: self.authorId,
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
                self.likeCountLabel.text = String(likesAccount.count)
                self.likeButton.isSelected = likesAccount.contains(self.authorId)
            } else {
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
                    completion(false)
                } else {
                    userRef.updateData([
                        "bookmarkPost": FieldValue.arrayUnion([postId])
                    ]) { error in
                        if let error = error {
                            completion(false)
                        } else {
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
                    completion(false)
                } else {
                    userRef.updateData([
                        "bookmarkPost": FieldValue.arrayRemove([postId])
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
                FirebaseManager.shared.loadPoemById(matchedTrip.poemId) { poem in
                    DispatchQueue.main.async {
                        self.tripTitleLabel.text = poem.title
                        self.poemTitle = poem.title
                        self.poemId = poem.id
                        
                        if let headerView = self.tableView.tableHeaderView {
                            headerView.setNeedsLayout()
                            headerView.layoutIfNeeded()
                            let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                            var frame = headerView.frame
                            frame.size.height = headerHeight
                            headerView.frame = frame
                            self.tableView.tableHeaderView = headerView
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}

extension ArticleViewController {
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        isUpdatingLikeStatus = true
        sender.isSelected.toggle()
        saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
            if success {
                self.updateLikesData()
            } else {
                sender.isSelected.toggle()
            }
            self.isUpdatingLikeStatus = false
        }
    }
    
    @objc func didTapCommentButton(_ sender: UIButton) {
        if isScrolledToFirstComment {
            commentTextField.becomeFirstResponder()
        } else {
            scrollToFirstComment()
            isScrolledToFirstComment = true
        }
    }
    
    func scrollToFirstComment() {
        let firstCommentIndexPath = IndexPath(row: 0, section: 0)
        if comments.count > 0 {
            tableView.scrollToRow(at: firstCommentIndexPath, at: .top, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isScrolledToFirstComment = false
            }
        } else {
            commentTextField.becomeFirstResponder()
        }
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        saveBookmarkData(postId: postId, userId: authorId, isBookmarked: sender.isSelected) { success in
            if success {
                self.updateBookmarkData()
            } else {
                sender.isSelected.toggle()
            }
        }
    }
    
    @objc func didTapSendButton() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let commentContent = commentTextField.text, !commentContent.isEmpty else {
            return
        }
        saveComment(userId: userId, postId: postId, commentContent: commentContent) { success in
            if success {
                self.loadComments()
                self.commentTextField.text = ""
                
                FirebaseManager.shared.fetchUserData(userId: userId) { result in
                    switch result {
                    case .success(let data):
                        let userName = data["userName"] as? String ?? ""
                        
                        FirebaseManager.shared.saveNotification(
                            to: self.authorId, // 確保這裡有正確的 postOwnerId
                            from: userId,
                            postId: self.postId,
                            type: 1,  // 1 表示評論
                            subType: nil,
                            title: "你的日記有新的評論！",
                            message: "\(userName) 評論了你的日記： \(commentContent)",
                            actionUrl: nil,
                            priority: 0
                        ) { result in
                            switch result {
                            case .success:
                                print("通知发送成功")
                            case .failure(let error):
                                print("通知发送失败: \(error.localizedDescription)")
                            }
                        }
                        
                    case .failure(let error):
                        print("加載使用者資料失敗: \(error.localizedDescription)")
                    }
                }
            } else {
            }
        }
    }
}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func setupTableView() {
        
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
        tableView.estimatedRowHeight = 180
        tableView.rowHeight = UITableView.automaticDimension
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-60)
        }
    }
    
    func createHeaderView() -> UIView {
        let headerView = UIView()
        setupHeaderView(in: headerView)
        setupActionButtons(in: headerView)
        return headerView
    }
    
    func setupHeaderView(in headerView: UIView) {
        
        headerView.addSubview(awardLabelView)
        titleLabel.text = articleTitle
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .deepBlue
        headerView.addSubview(titleLabel)
        
        authorLabel.text = articleAuthor
        authorLabel.numberOfLines = 0
        headerView.addSubview(authorLabel)
        headerView.addSubview(contentLabel)
        
        dateLabel.text = articleDate
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .gray
        dateLabel.numberOfLines = 0
        headerView.addSubview(dateLabel)
        
        setupAvatar()
        headerView.addSubview(avatarImageView)
        
        tripView.backgroundColor = .deepBlue
        tripView.layer.cornerRadius = 25
        headerView.addSubview(tripView)
        
        tripTitleLabel.textColor = .white
        tripTitleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 18)
        tripView.addSubview(tripTitleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.leading.equalTo(avatarImageView)
            make.trailing.equalTo(headerView).offset(-16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView).offset(-10)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(15)
        }
        
        awardLabelView.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(6)
            make.leading.equalTo(authorLabel)
            make.height.equalTo(20)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(headerView).offset(-16)
        }
        
        headerView.addSubview(photoContainerView)
        photoContainerView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.width.equalTo(headerView).multipliedBy(0.9)
            make.centerX.equalTo(headerView)
        }
        
        tripView.snp.makeConstraints { make in
            make.top.equalTo(photoContainerView.snp.bottom).offset(12)
            make.width.equalTo(headerView).multipliedBy(0.9)
            make.height.equalTo(50)
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
        
        avatarImageView.image = UIImage(named: "user-placeholder")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        headerView.addSubview(likeButton)
        headerView.addSubview(commentButton)
        headerView.addSubview(collectButton)
        
        setupButton()
        
        likeCountLabel.text = "0"
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        headerView.addSubview(likeCountLabel)
        
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
        setupLabel()
    }
    
    func setupLabel() {
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 26)
        authorLabel.font = UIFont(name: "NotoSerifHK-Black", size: 22)
        contentLabel.font = UIFont(name: "NotoSerifHK-Black", size: 18)
        contentLabel.lineSpacing = 7
        contentLabel.text = articleContent
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.textColor = .darkGray
        contentLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width * 0.9
        tripTitleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 18)
    }
    
    func setupButton() {
        
        likeButton.setImage(UIImage(named: "normal_heart"), for: .normal)
        likeButton.setImage(UIImage(named: "selected_heart"), for: .selected)
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        commentButton.setImage(UIImage(named: "normal_comment"), for: .normal)
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        collectButton.setImage(UIImage(named: "normal_bookmark"), for: .normal)
        collectButton.setImage(UIImage(named: "selected_bookmark"), for: .selected)
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
    }
    
    func updateHeaderViewLayout() {
        if let headerView = self.tableView.tableHeaderView {
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
            let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var frame = headerView.frame
            frame.size.height = headerHeight
            headerView.frame = frame
            self.tableView.tableHeaderView = headerView
            self.tableView.layoutIfNeeded()
        }
    }
    
    func setupActionButtons(in headerView: UIView) {
        
        likeButton.tintColor = UIColor.systemBlue
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        likeCountLabel.text = "0"
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        commentButton.tintColor = UIColor.systemGreen
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        
        collectButton.tintColor = UIColor.systemPink
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
    }
    
    func setupTripViewAction() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openPresent))
        tripView.addGestureRecognizer(tapGesture)
    }
    
    func setupPhotos() {
        for subview in photoContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        let numberOfPhotos = photoUrls.count
        
        if numberOfPhotos == 1 {
            let imageView = createImageView(urlString: photoUrls[0], index: 0)
            photoContainerView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(200)
            }
        } else if numberOfPhotos == 2 {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.distribution = .fillEqually
            
            for (index, url) in photoUrls.enumerated() {
                let imageView = createImageView(urlString: url, index: index)
                stackView.addArrangedSubview(imageView)
            }
            
            photoContainerView.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(150)
            }
        } else if numberOfPhotos == 3 {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.distribution = .fillEqually
            
            for (index, url) in photoUrls.enumerated() {
                let imageView = createImageView(urlString: url, index: index)
                stackView.addArrangedSubview(imageView)
            }
            
            photoContainerView.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(150)
            }
        } else {
            let columns = 3
            let rows = Int(ceil(Double(numberOfPhotos) / Double(columns)))
            let gridStackView = UIStackView()
            gridStackView.axis = .vertical
            gridStackView.spacing = 8
            gridStackView.distribution = .fillEqually
            
            for row in 0..<rows {
                let rowStackView = UIStackView()
                rowStackView.axis = .horizontal
                rowStackView.spacing = 8
                rowStackView.distribution = .fillEqually
                
                for column in 0..<columns {
                    let index = row * columns + column
                    if index < photoUrls.count {
                        let imageView = createImageView(urlString: photoUrls[index], index: index)
                        rowStackView.addArrangedSubview(imageView)
                    } else {
                        let placeholderView = UIView()
                        rowStackView.addArrangedSubview(placeholderView)
                    }
                }
                
                gridStackView.addArrangedSubview(rowStackView)
            }
            
            photoContainerView.addSubview(gridStackView)
            gridStackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(rows * 100 + (rows - 1) * 8)
            }
        }
    }
    
    func createImageView(urlString: String, index: Int) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.isUserInteractionEnabled = true
        
        if let url = URL(string: urlString) {
            imageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImage(_:)))
        imageView.addGestureRecognizer(tapGesture)
        imageView.tag = index
        
        return imageView
    }
    
    @objc func didTapImage(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }
        let index = imageView.tag
        
        var uiImages: [UIImage] = []
        let dispatchGroup = DispatchGroup()
        
        let syncQueue = DispatchQueue(label: "com.example.imageSyncQueue")
        
        for urlString in photoUrls {
            if let url = URL(string: urlString) {
                dispatchGroup.enter()
                KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { result in
                    switch result {
                    case .success(let value):
                        syncQueue.sync {
                            uiImages.append(value.image)
                        }
                    case .failure(let error):
                        print("圖片加載失敗: \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let fullScreenVC = FullScreenImageViewController()
            fullScreenVC.images = uiImages
            fullScreenVC.startingIndex = index
            
            self.navigationController?.pushViewController(fullScreenVC, animated: true)
        }
    }
    
    @objc func dismissFullScreenImage(_ sender: Any) {
        if let window = UIApplication.shared.keyWindow {
            for subview in window.subviews {
                if subview is UIImageView && subview.backgroundColor == .black {
                    subview.removeFromSuperview()
                }
            }
        }
    }
    
    @objc func openPresent() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.getTripDataById()
            DispatchQueue.main.async {
                let articleTripVC = ArticleTripViewController()
                articleTripVC.modalPresentationStyle = .pageSheet
                articleTripVC.tripId = self.tripId
                articleTripVC.poemId = self.poemId
                articleTripVC.postUsernameLabel.text = self.articleAuthor
                articleTripVC.poemTitleLabel.text = "〈\(self.poemTitle)〉之旅"
                self.navigationController?.pushViewController(articleTripVC, animated: true)
            }
        }
    }
    
    func getTripDataById() {
        DispatchQueue.global(qos: .userInitiated).async {
            let db = Firestore.firestore()
            
            db.collection("trips").whereField("id", isEqualTo: self.tripId).getDocuments { snapshot, error in
                if let error = error {
                    return
                }
                
                if let documents = snapshot?.documents, let document = documents.first {
                    
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
                       let startTime = (data["startTime"] as? Timestamp)?.dateValue() {
                        
                        let places = placesData.compactMap { placeDict in
                            return placeDict["id"] as? String
                        }
                        
                        let poem = Poem(
                            id: poemData["id"] as? String ?? "",  // 加入 poem 的 ID
                            title: title,
                            poetry: poetry,
                            content: original, // 假設 content 是來自 original
                            tag: tag,
                            season: poemData["season"] as? Int,  // 加入 season
                            weather: poemData["weather"] as? Int, // 加入 weather
                            time: poemData["time"] as? Int // 加入 time
                        )
                        
                        let trip = Trip(
                            poemId: poem.id,  // 使用 poemId
                            id: self.tripId,
                            placeIds: places,
                            keywordPlaceIds: nil,
                            tag: tag,
                            season: season,
                            weather: weather,
                            startTime: startTime
                        )
                    } else {
                    }
                } else {
                }
            }
        }
    }
        
    func setupAvatar() {
        
        FirebaseManager.shared.fetchUserData(userId: authorId) { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    DispatchQueue.main.async {
                        
                        self.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                } else {
                }
            case .failure(let error):
                print("加載貼文作者的資料失敗: \(error.localizedDescription)")
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAvatar))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func didTapAvatar() {
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = authorId
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        if comments.count > 0 {
            let comment = comments[indexPath.row]
            
            cell.avatarImageView.image = UIImage(named: "user-placeholder")
            cell.contentLabel.text = comment["content"] as? String
            cell.usernameLabel.text = comment["username"] as? String
            
            if let createdAtTimestamp = comment["createdAt"] as? Timestamp {
                let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                cell.createdAtLabel.text = createdAtString
            }
            
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
            return
        }
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
}
