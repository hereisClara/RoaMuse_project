import Foundation
import UIKit
import SnapKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher
import MJRefresh

class UserProfileViewController: UIViewController {
    
    let headerView = UIView()
    var isShowingFollowers: Bool = true
    let postsNumberLabel = UILabel()
    let postsTextLabel = UILabel()
    var userId: String?
    var bottomSheetManager: BottomSheetManager?
    var userBottomSheetManager: BottomSheetManager?
    let awardLabelView = AwardLabelView(title: "初心者", backgroundColor: .systemGray)
    let tableView = UITableView()
    let userNameLabel = UILabel()
    let fansNumberLabel = UILabel()
    let followingNumberLabel = UILabel()
    let introductionLabel = UILabel()
    let newView = UIView()
    
    let fansTextLabel = UILabel()
    let followingTextLabel = UILabel()
    let regionLabelView = RegionLabelView(region: nil)
    var posts: [[String: Any]] = []
    var followButton = UIButton()
    
    let avatarImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(didTapNaviMoreButton))
        self.navigationItem.rightBarButtonItem = moreButton
        
        if let currentUserId = UserDefaults.standard.string(forKey: "userId"), currentUserId == userId {
            followButton.isHidden = true
        }
        loadUserPosts()
        checkIfFollowing()
        setupTableView()
        setupHeaderView()
        setupRefreshControl()
        guard let userId = userId else { return }
        
        bottomSheetManager = BottomSheetManager(parentViewController: self, sheetHeight: 200)
        bottomSheetManager?.addActionButton(title: "檢舉貼文", textColor: .red) {
            self.presentImpeachAlert()
        }
        bottomSheetManager?.addActionButton(title: "取消", textColor: .gray) {
            self.bottomSheetManager?.dismissBottomSheet()
        }
        
        bottomSheetManager?.setupBottomSheet()
        
        userBottomSheetManager = BottomSheetManager(parentViewController: self, sheetHeight: 300)
        userBottomSheetManager?.addActionButton(title: "封鎖用戶", textColor: .black) {
            self.blockUser()
        }
        userBottomSheetManager?.addActionButton(title: "檢舉用戶", textColor: .red) {
            self.presentUserImpeachAlert()
        }
        userBottomSheetManager?.addActionButton(title: "取消", textColor: .gray) {
            self.userBottomSheetManager?.dismissBottomSheet()
        }
        userBottomSheetManager?.setupBottomSheet()
        
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userNameLabel.text = userName
                }
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                if let followers = data["followers"] as? [String] {
                    self?.fansNumberLabel.text = String(followers.count)
                }
                if let followings = data["following"] as? [String] {
                    self?.followingNumberLabel.text = String(followings.count)
                }
                if let region = data["region"] as? String {
                    self?.regionLabelView.updateRegion(region)
                }
                if let introduction = data["introduction"] as? String {
                    self?.introductionLabel.text = introduction
                    self?.updateTableHeaderViewHeight()
                }
                
            case .failure(let error):
                print("獲取用戶資料失敗: \(error.localizedDescription)")
            }
        }
        
        FirebaseManager.shared.loadAwardTitle(forUserId: userId) { (result: Result<(String, Int), Error>) in
            switch result {
            case .success(let (awardTitle, item)):
                let title = awardTitle
                self.awardLabelView.updateTitle(title)
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
        tabBarController?.tabBar.isHidden = true
        
        FirebaseManager.shared.fetchUserData(userId: userId ?? "") { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userNameLabel.text = userName
                }
                
                if let followers = data["followers"] as? [String] {
                    self?.fansNumberLabel.text = String(followers.count)
                }
                
                // 顯示 avatar 圖片
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
                if let followings = data["following"] as? [String] {
                    self?.followingNumberLabel.text = String(followings.count)
                }
                
                if let region = data["region"] as? String {
                    self?.regionLabelView.updateRegion(region)
                }
                
                if let introduction = data["introduction"] as? String {
                    self?.introductionLabel.text = introduction
                    self?.updateTableHeaderViewHeight()
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeaderViewHeight()
    }
    
    func setupRefreshControl() {
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.reloadAllData()
        })
    }
    
    func reloadAllData() {
        guard let userId = userId else {
            self.tableView.mj_header?.endRefreshing()
            return
        }
        
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userNameLabel.text = userName
                }
                // 顯示 avatar 圖片
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
                if let followers = data["followers"] as? [String] {
                    self?.fansNumberLabel.text = String(followers.count)
                }
                
                if let followings = data["following"] as? [String] {
                    self?.followingNumberLabel.text = String(followings.count)
                }
                
                if let region = data["region"] as? String {
                    self?.regionLabelView.updateRegion(region)
                }
                
                if let introduction = data["introduction"] as? String {
                    self?.introductionLabel.text = introduction
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
        
        // 重新加載用戶貼文
        loadUserPosts()
        
        // 結束刷新
        DispatchQueue.main.async {
            self.tableView.mj_header?.endRefreshing()
        }
    }
    
    func setupHeaderView() {
        headerView.backgroundColor = .systemGray5
        headerView.layer.cornerRadius = 20
        headerView.layer.masksToBounds = true
        headerView.layer.borderColor = UIColor.deepBlue.cgColor
        headerView.layer.borderWidth = 2
        
        [userNameLabel, awardLabelView, avatarImageView, fansTextLabel, followingTextLabel, fansNumberLabel,
         followingNumberLabel, introductionLabel, followButton, regionLabelView].forEach { headerView.addSubview($0) }
        
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.image = UIImage(named: "user-placeholder")
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)

        awardLabelView.backgroundColor = .systemGray3
        awardLabelView.layer.cornerRadius = 8
        awardLabelView.clipsToBounds = true
        setupLabel()
        setupPostsStackView()
        let fansStackView = UIStackView(arrangedSubviews: [fansNumberLabel, fansTextLabel])
        fansStackView.axis = .vertical
        fansStackView.alignment = .center
        fansStackView.spacing = 0
        headerView.addSubview(fansStackView)
        
        let followingStackView = UIStackView(arrangedSubviews: [followingNumberLabel, followingTextLabel])
        followingStackView.axis = .vertical
        followingStackView.alignment = .center
        followingStackView.spacing = 0
        headerView.addSubview(followingStackView)
        
        let postStackView = UIStackView(arrangedSubviews: [postsNumberLabel, postsTextLabel])
        postStackView.axis = .vertical
        postStackView.alignment = .center
        postStackView.spacing = 0
        headerView.addSubview(postStackView)
        
        introductionLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
            make.leading.equalTo(headerView).offset(16)
            make.trailing.equalTo(headerView).offset(-16)
            make.bottom.equalTo(fansStackView.snp.top).offset(-12)
        }
        
        followButton.setTitle("追蹤", for: .normal)
        followButton.setTitle("已追蹤", for: .selected)
        followButton.setTitleColor(.deepBlue, for: .normal)
        followButton.backgroundColor = .clear
        followButton.layer.borderColor = UIColor.deepBlue.cgColor
        followButton.layer.borderWidth = 1
        followButton.layer.cornerRadius = 10
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        followButton.addTarget(self, action: #selector(handleFollowButtonTapped), for: .touchUpInside)
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(headerView).offset(16)
            make.width.height.equalTo(100)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(8)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.height.equalTo(50)
        }
        
        awardLabelView.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(4)
            make.leading.equalTo(userNameLabel)
            make.height.equalTo(24)
        }
        
        fansStackView.snp.makeConstraints { make in
            make.centerX.equalTo(headerView)
            make.bottom.equalTo(headerView.snp.bottom).offset(-16)
        }
        
        postStackView.snp.makeConstraints { make in
            make.centerY.equalTo(fansStackView)
            make.centerX.equalTo(fansStackView.snp.leading).offset(-80)  // 间距
        }
        
        followingStackView.snp.makeConstraints { make in
            make.centerY.equalTo(fansStackView)
            make.centerX.equalTo(fansStackView.snp.trailing).offset(80)  // 间距
        }
        
        regionLabelView.snp.makeConstraints { make in
            make.leading.equalTo(awardLabelView)
            make.height.equalTo(24)
            make.top.equalTo(awardLabelView.snp.bottom).offset(4)
        }
        
        followButton.snp.makeConstraints { make in
            make.trailing.equalTo(headerView).offset(-16)
            make.centerY.equalTo(userNameLabel)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
        
        let fansTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFans))
        fansStackView.addGestureRecognizer(fansTapGesture)
        fansStackView.isUserInteractionEnabled = true
        
        let followingTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFollowing))
        followingStackView.addGestureRecognizer(followingTapGesture)
        followingStackView.isUserInteractionEnabled = true
        
        tableView.tableHeaderView = headerView
    }
    
    func setupPostsStackView() {
        postsNumberLabel.text = String(posts.count)
        postsNumberLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        
        postsTextLabel.text = "Posts"
        postsTextLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 12)
        postsTextLabel.textColor = .gray
        postsTextLabel.textAlignment = .center
    }
    
    func updateTableHeaderViewHeight() {
        guard let header = tableView.tableHeaderView else { return }

        header.setNeedsLayout()
        header.layoutIfNeeded()

        let newSize = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var headerFrame = header.frame
        headerFrame.size.height = newSize.height
        header.frame = headerFrame
        print("HeaderView frame: \(header.frame)")
        tableView.tableHeaderView = header
    }
    
    func setupLabel() {
        
        fansNumberLabel.text = "0"
        fansNumberLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        fansTextLabel.text = "Followers"
        fansTextLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 12)
        fansTextLabel.textColor = .gray
        fansTextLabel.textAlignment = .center
        
        followingNumberLabel.text = "0"
        followingNumberLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        followingTextLabel.text = "Following"
        followingTextLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 12)
        followingTextLabel.textColor = .gray
        followingTextLabel.textAlignment = .center
        
        userNameLabel.text = "新用戶"
        userNameLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        userNameLabel.textColor = .deepBlue
        introductionLabel.numberOfLines = 3
        introductionLabel.lineSpacing = 6
        introductionLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        introductionLabel.textColor = .darkGray
        regionLabelView.regionLabel.textColor = .white
        regionLabelView.regionLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
    }
    
    @objc func didTapFans() {
        let userListVC = UserListViewController()
        userListVC.isShowingFollowers = true
        userListVC.userId = self.userId
        navigationController?.pushViewController(userListVC, animated: true)
    }
    
    @objc func didTapFollowing() {
        let userListVC = UserListViewController()
        userListVC.isShowingFollowers = false
        userListVC.userId = self.userId
        navigationController?.pushViewController(userListVC, animated: true)
    }
    
    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"), options: [
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ])
    }
}

extension UserProfileViewController {
    @objc func handleFollowButtonTapped() {
        guard let followedUserId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        let followedUserRef = Firestore.firestore().collection("users").document(followedUserId)
        
        if followButton.isSelected {
            
            currentUserRef.updateData([
                "following": FieldValue.arrayRemove([followedUserId])
            ]) { error in
                if let error = error {
                } else {
                    followedUserRef.updateData([
                        "followers": FieldValue.arrayRemove([currentUserId])
                    ]) { error in
                        if let error = error {
                        } else {
                            DispatchQueue.main.async {
                                self.followButton.isSelected = false
                            }
                        }
                    }
                }
            }
        } else {
            // 追蹤
            currentUserRef.updateData([
                "following": FieldValue.arrayUnion([followedUserId])
            ]) { error in
                if let error = error {
                } else {
                    followedUserRef.updateData([
                        "followers": FieldValue.arrayUnion([currentUserId])
                    ]) { error in
                        if let error = error {
                        } else {
                            DispatchQueue.main.async {
                                self.followButton.isSelected = true
                            }
                            
                            FirebaseManager.shared.fetchUserData(userId: currentUserId ?? "") { result in
                                switch result {
                                case .success(let data):
                                    let userName = data["userName"] as? String ?? ""
                                    
                                    FirebaseManager.shared.saveNotification(
                                        to: self.userId ?? "",  // 被追蹤者的ID
                                        from: currentUserId,      // 發起追蹤的當前用戶ID
                                        postId: nil,       // 追蹤操作與貼文無關，因此這裡是 nil
                                        type: 2,           // 2 表示追蹤
                                        subType: nil,
                                        title: "你有一個新追蹤者！",
                                        message: "\(userName) 開始追蹤你了",
                                        actionUrl: nil,    // 可選 URL，點擊後跳轉的動作，這裡可以是 profile 頁面
                                        priority: 0
                                    ) { result in
                                        switch result {
                                        case .success:
                                            print("追蹤通知发送成功")
                                        case .failure(let error):
                                            print("追蹤通知发送失败: \(error.localizedDescription)")
                                        }
                                    }
                                    
                                case .failure(let error):
                                    print("加載使用者資料失敗: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension UserProfileViewController {
    func setupChatButton() {
        let chatButton = UIButton()
        chatButton.setImage(UIImage(systemName: "bubble.left.and.bubble.right"), for: .normal)
        self.view.addSubview(chatButton)
        
        chatButton.snp.makeConstraints { make in
            make.width.height.equalTo(45)
            make.top.equalTo(followButton).offset(24)  // 調整頂部偏移量
            make.trailing.equalTo(self.view.safeAreaLayoutGuide).offset(-20)
        }
        
        chatButton.addTarget(self, action: #selector(toChatPage), for: .touchUpInside)
    }
    
    @objc func toChatPage() {
        // 获取当前用户的 userId 和被聊天的对象 userId
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId"),
              let chatUserId = userId else { return }
        
        // 通过现有数据库去检查是否已有聊天会话，若无则创建
        fetchOrCreateChatSession(currentUserId: currentUserId, chatUserId: chatUserId) { chatId in
            let chatVC = ChatViewController()
            chatVC.chatId = chatId  // 传递聊天会话的 chatId
            chatVC.chatUserId = chatUserId
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    func fetchOrCreateChatSession(currentUserId: String, chatUserId: String, completion: @escaping (String) -> Void) {
        let chatRef = Firestore.firestore().collection("chats")
        let userRef = Firestore.firestore().collection("users")
        
        // Step 1: 檢查是否已經存在聊天會話
        chatRef
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("查詢聊天會話失敗: \(error)")
                    return
                }
                
                // 遍歷所有會話，檢查是否有相同參與者
                if let documents = snapshot?.documents {
                    for document in documents {
                        let data = document.data()
                        let participants = data["participants"] as? [String] ?? []
                        
                        if participants.contains(chatUserId) {
                            // 如果會話已經存在，返回 chatId
                            completion(document.documentID)
                            return
                        }
                    }
                }
                
                // Step 2: 如果沒有找到，創建新的會話
                let chatId = chatRef.document().documentID // 自定義生成的 chatId
                
                // 獲取當前用戶和聊天對象的頭像
                userRef.document(chatUserId).getDocument { (chatUserSnapshot, error) in
                    guard let chatUserData = chatUserSnapshot?.data(),
                          let chatUserAvatar = chatUserData["photo"] as? String else {
                        print("無法獲取聊天對象頭像")
                        return
                    }
                    
                    userRef.document(currentUserId).getDocument { (currentUserSnapshot, error) in
                        guard let currentUserData = currentUserSnapshot?.data(),
                              let currentUserAvatar = currentUserData["photo"] as? String else {
                            print("無法獲取當前用戶頭像")
                            return
                        }
                        
                        // 準備新的聊天數據
                        let newChatData: [String: Any] = [
                            "participants": [currentUserId, chatUserId],
                            "lastMessage": "",
                            "lastMessageTime": FieldValue.serverTimestamp(),
                            "chatUserProfileImage": chatUserAvatar,   // 保存聊天對象頭像
                            "currentUserProfileImage": currentUserAvatar // 保存當前用戶頭像
                        ]
                        
                        // Step 3: 將聊天數據上傳到 Firestore，指定 chatId
                        chatRef.document(chatId).setData(newChatData) { error in
                            if let error = error {
                                print("創建新的聊天會話失敗: \(error)")
                            } else {
                                print("新的聊天會話創建成功，chatId: \(chatId)")
                                // 返回 chatId
                                completion(chatId)
                            }
                        }
                    }
                }
            }
    }
    
}

extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 250
        tableView.rowHeight = UITableView.automaticDimension
        tableView.snp.makeConstraints { make in
            make.width.equalTo(view).multipliedBy(0.9)
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        
        guard let cell = cell else { return UITableViewCell() }
        
        let post = posts[indexPath.row]
        let title = post["title"] as? String ?? "無標題"
        let content = post["content"] as? String ?? "no text"
        
        cell.titleLabel.text = title
        cell.contentLabel.text = content
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        let postId = post["id"] as? String ?? ""
        
        cell.configurePhotoStackView(with: post["photoUrls"] as? [String] ?? [])
        cell.layoutIfNeeded()
        cell.likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        cell.configureMoreButton { [weak self] in
            self?.bottomSheetManager?.showBottomSheet()
        }
        
        if let createdAtTimestamp = post["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == postId
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = String(likesAccount.count)
                    cell.likeButton.isSelected = likesAccount.contains(self.userId ?? "")
                }
            } else {
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = "0"
                    cell.likeButton.isSelected = false // 依據狀態設置未選中
                }
            }
        }
        
        FirebaseManager.shared.fetchUserData(userId: self.userId ?? "") { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    
                    DispatchQueue.main.async {
                        cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                }
                
                cell.userNameLabel.text = data["userName"] as? String
                
                FirebaseManager.shared.loadAwardTitle(forUserId: self.userId ?? "") { (result: Result<(String, Int), Error>) in
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
                print("加載用戶大頭貼失敗: \(error.localizedDescription)")
            }
        }
        
        // 檢查收藏狀態
        FirebaseManager.shared.isContentBookmarked(forUserId: userId ?? "", id: postId) { isBookmarked in
            cell.collectButton.isSelected = isBookmarked
        }
        
        cell.containerView.layer.borderColor = UIColor.deepBlue.cgColor
        cell.containerView.layer.borderWidth = 2
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        let articleVC = ArticleViewController()
        
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
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 250
//    }
    
    func loadUserPosts() {
        guard let userId = userId else { return }
        
        FirebaseManager.shared.loadSpecifyUserPost(forUserId: userId) { [weak self] postsArray in
            guard let self = self else { return }
            self.posts = postsArray.sorted(by: { (post1, post2) -> Bool in
                if let createdAt1 = post1["createdAt"] as? Timestamp, let createdAt2 = post2["createdAt"] as? Timestamp {
                    return createdAt1.dateValue() > createdAt2.dateValue()
                }
                return false
            })
            DispatchQueue.main.async {
                self.postsNumberLabel.text = String(self.posts.count)
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            let postId = post["id"] as? String ?? ""
            let postOwnerId = post["userId"] as? String ?? ""
            
            FirebaseManager.shared.fetchUserData(userId: userId ?? "") { result in
                switch result {
                case .success(let data):
                let userName = data["userName"] as? String ?? ""
                FirebaseManager.shared.saveNotification(
                    to: postOwnerId,
                    from: self.userId ?? "",
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
            updateLikeStatus(postId: postId, isLiked: sender.isSelected)
        }
    }
    
    func updateLikeStatus(postId: String, isLiked: Bool) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        if isLiked {
            postRef.updateData([
                "likesAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("按讚失敗: \(error.localizedDescription)")
                } else {
                    
                }
            }
        } else {
            postRef.updateData([
                "likesAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消按讚失敗: \(error.localizedDescription)")
                } else {
                    
                }
            }
        }
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            let postId = post["id"] as? String ?? ""
            
            updateBookmarkStatus(postId: postId, isBookmarked: sender.isSelected)
        }
    }
    
    func updateBookmarkStatus(postId: String, isBookmarked: Bool) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        if isBookmarked {
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("收藏失敗: \(error.localizedDescription)")
                } else {
                    
                }
            }
        } else {
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消收藏失敗: \(error.localizedDescription)")
                } else {
                    
                }
            }
        }
    }
    
    func presentImpeachAlert() {
        let alertController = UIAlertController(title: "檢舉貼文", message: "你確定要檢舉這篇貼文嗎？", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: "確定", style: .destructive) { _ in
            print("已檢舉貼文")
            self.bottomSheetManager?.dismissBottomSheet()
        }
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func didTapNaviMoreButton() {
        userBottomSheetManager?.showBottomSheet()
    }
    
    func presentUserImpeachAlert() {
        let alertController = UIAlertController(title: "檢舉用戶", message: "你確定要檢舉這個用戶嗎？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let confirmAction = UIAlertAction(title: "確定", style: .destructive) { _ in
            print("已檢舉用戶")
            self.userBottomSheetManager?.dismissBottomSheet()
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func blockUser() {
        guard let blockedUserId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId 或當前用戶 ID")
            return
        }
        
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserId)
        let blockedUserRef = db.collection("users").document(blockedUserId)
        
        currentUserRef.updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUserId])
        ]) { [weak self] error in
            if let error = error {
                print("封鎖用戶失敗: \(error.localizedDescription)")
                return
            } else {
                print("成功封鎖用戶")
                
                self?.removeFromFollowersAndFollowing(currentUserId: currentUserId, blockedUserId: blockedUserId) {
                    DispatchQueue.main.async {
                        self?.userBottomSheetManager?.dismissBottomSheet()
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    func removeFromFollowersAndFollowing(currentUserId: String, blockedUserId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserId)
        let blockedUserRef = db.collection("users").document(blockedUserId)
        
        blockedUserRef.updateData([
            "following": FieldValue.arrayRemove([currentUserId]),
            "followers": FieldValue.arrayRemove([currentUserId])
        ]) { error in
            if let error = error {
                print("無法從封鎖對象的 following 和 followers 中移除當前用戶: \(error.localizedDescription)")
            } else {
                print("已從封鎖對象的 following 和 followers 中移除當前用戶")
            }
        }
        
        currentUserRef.updateData([
            "following": FieldValue.arrayRemove([blockedUserId]),
            "followers": FieldValue.arrayRemove([blockedUserId])
        ]) { error in
            if let error = error {
                print("無法從當前用戶的 following 和 followers 中移除封鎖對象: \(error.localizedDescription)")
            } else {
                print("已從當前用戶的 following 和 followers 中移除封鎖對象")
            }
            completion()
        }
    }
}

extension UserProfileViewController {
    
    func checkIfFollowing() {
        guard let userId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        if currentUserId == userId {
            followButton.isHidden = true
            return
        }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        currentUserRef.getDocument { snapshot, error in
            if let error = error {
                return
            }
            
            guard let data = snapshot?.data(), let following = data["following"] as? [String] else {
                return
            }
            
            DispatchQueue.main.async {
                // 如果當前用戶已經追蹤該用戶，則設置為已選擇狀態
                self.followButton.isSelected = following.contains(userId)
                if self.followButton.isSelected {
                    self.followButton.setTitle("已追蹤", for: .selected)
                }
            }
        }
    }
}
