import Foundation
import UIKit
import SnapKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher
import MJRefresh

class UserProfileViewController: UIViewController {
    
    var userId: String?
    var bottomSheetManager: BottomSheetManager?
    var userBottomSheetManager: BottomSheetManager?
    let awardLabelView = AwardLabelView(title: "稱號：", backgroundColor: .systemGray)
    let tableView = UITableView()
    let userNameLabel = UILabel()
    let fansNumberLabel = UILabel()
        let followingNumberLabel = UILabel()
        
        let fansTextLabel = UILabel()
        let followingTextLabel = UILabel()
    
    var posts: [[String: Any]] = []
    var followButton = UIButton()
    
    let avatarImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(didTapNaviMoreButton))
        self.navigationItem.rightBarButtonItem = moreButton
        
        if let currentUserId = UserDefaults.standard.string(forKey: "userId"), currentUserId == userId {
                // 如果是自己，则隐藏追踪按钮
                followButton.isHidden = true
            }
        
        checkIfFollowing()
        setupTableView()
        setupUI()
        setupChatButton()
        setupRefreshControl()
        guard let userId = userId else {
            print("無法獲取 userId")
            return
        }
        
        bottomSheetManager = BottomSheetManager(parentViewController: self, sheetHeight: 300)
        
        bottomSheetManager?.addActionButton(title: "隱藏貼文") {
            print("隱藏貼文")
        }
        
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
                
            case .failure(let error):
                print("獲取用戶資料失敗: \(error.localizedDescription)")
            }
        }
        
        loadUserPosts()
        
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
    
    func setupRefreshControl() {
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.reloadAllData()  // 在下拉刷新時重新加載所有資料
        })
    }
    
    func reloadAllData() {
        guard let userId = userId else {
            self.tableView.mj_header?.endRefreshing() // 保證刷新結束
            return
        }
        
        // 重新加載用戶資料
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
    
    func setupUI() {
        // Header view customization based on provided image design
        let headerView = UIView()
        headerView.backgroundColor = .systemGray5
        headerView.layer.cornerRadius = 20
        headerView.layer.masksToBounds = true
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 220)
        
        // Avatar image view
        avatarImageView.layer.cornerRadius = 45
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .blue
        headerView.addSubview(avatarImageView)
        
        // User name label
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(userNameLabel)
        
        // Award Label (Replaces 打開卡片)
        awardLabelView.backgroundColor = .systemGray3
        awardLabelView.layer.cornerRadius = 8
        awardLabelView.clipsToBounds = true
        headerView.addSubview(awardLabelView)
        
        fansNumberLabel.text = "0"
                fansNumberLabel.font = UIFont.systemFont(ofSize: 16)
                fansTextLabel.text = "Followers"
                fansTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                fansTextLabel.textColor = .gray
                fansTextLabel.textAlignment = .center
                
                followingNumberLabel.text = "0"
                followingNumberLabel.font = UIFont.systemFont(ofSize: 16)
                followingTextLabel.text = "Following"
                followingTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                followingTextLabel.textColor = .gray
                followingTextLabel.textAlignment = .center
                
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
        
        // Follow button
        followButton.setTitle("追蹤", for: .normal)
        followButton.setTitle("已追蹤", for: .selected)
        followButton.setTitleColor(.deepBlue, for: .normal)
        followButton.backgroundColor = .clear
        followButton.layer.borderColor = UIColor.deepBlue.cgColor
        followButton.layer.borderWidth = 1
        followButton.layer.cornerRadius = 10
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        followButton.addTarget(self, action: #selector(handleFollowButtonTapped), for: .touchUpInside)
        headerView.addSubview(followButton)
        
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalTo(headerView).offset(16)
            make.width.height.equalTo(90)
            make.centerY.equalTo(headerView).offset(-10)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
        }
        
        awardLabelView.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
            make.width.equalTo(120)
            make.height.equalTo(24)
        }
        
        fansStackView.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.centerX.equalTo(avatarImageView)
        }
        
        followingStackView.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.leading.equalTo(fansStackView.snp.trailing).offset(40)
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
    
    @objc func didTapFans() {
        let userListVC = UserListViewController()
            userListVC.isShowingFollowers = true // 表示要显示粉丝列表
            userListVC.userId = self.userId
            navigationController?.pushViewController(userListVC, animated: true)
    }

    @objc func didTapFollowing() {
        let userListVC = UserListViewController()
            userListVC.isShowingFollowers = false // 表示要显示关注列表
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
    
    @objc func handleFollowButtonTapped() {
        guard let followedUserId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId 或當前用戶 ID")
            return
        }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        let followedUserRef = Firestore.firestore().collection("users").document(followedUserId)
        
        if followButton.isSelected {
            // 取消追蹤
            currentUserRef.updateData([
                "following": FieldValue.arrayRemove([followedUserId])
            ]) { error in
                if let error = error {
                    print("取消追蹤失敗: \(error.localizedDescription)")
                } else {
                    print("取消追蹤成功")
                    // 從被追蹤者的 followers 中移除當前用戶
                    followedUserRef.updateData([
                        "followers": FieldValue.arrayRemove([currentUserId])
                    ]) { error in
                        if let error = error {
                            print("從被追蹤者 followers 移除失敗: \(error.localizedDescription)")
                        } else {
                            print("已從被追蹤者的 followers 中移除")
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
                    print("追蹤失敗: \(error.localizedDescription)")
                } else {
                    print("追蹤成功")
                    // 同時在被追蹤者的 followers 中加入當前用戶
                    followedUserRef.updateData([
                        "followers": FieldValue.arrayUnion([currentUserId])
                    ]) { error in
                        if let error = error {
                            print("將當前用戶添加到 followers 失敗: \(error.localizedDescription)")
                        } else {
                            print("已添加當前用戶到被追蹤者的 followers")
                            DispatchQueue.main.async {
                                self.followButton.isSelected = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkIfFollowing() {
        guard let userId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId 或當前用戶 ID")
            return
        }
        
        // 如果是自己的頁面，隱藏追蹤按鈕
        if currentUserId == userId {
            followButton.isHidden = true
            return
        }

        // 檢查是否已經追蹤該用戶
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        currentUserRef.getDocument { snapshot, error in
            if let error = error {
                print("檢查追蹤狀態失敗: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(), let following = data["following"] as? [String] else {
                print("無法獲取追蹤數據")
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
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        
        guard let cell = cell else { return UITableViewCell() }
        
        let post = posts[indexPath.row]
        cell.titleLabel.text = post["title"] as? String ?? "無標題"
        cell.contentLabel.text = post["content"] as? String ?? "無內容"
        cell.configureMoreButton {
            self.bottomSheetManager?.showBottomSheet()
        }
        
        FirebaseManager.shared.fetchUserData(userId: self.userId ?? "") { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    
                    DispatchQueue.main.async {
                        cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                }
            case .failure(let error):
                print("加載用戶大頭貼失敗: \(error.localizedDescription)")
            }
        }
        
        FirebaseManager.shared.isContentBookmarked(forUserId: userId ?? "", id: post["id"] as? String ?? "") { isBookmarked in
            cell.collectButton.isSelected = isBookmarked
        }
        
        cell.selectionStyle = .none
        
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
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
            self.tableView.reloadData()
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
