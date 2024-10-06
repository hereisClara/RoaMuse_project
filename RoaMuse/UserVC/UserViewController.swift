//
//  UserViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit
import SnapKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher
import MJRefresh

class UserViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let headerView = UIView()
    let tableView = UITableView()
    let userNameLabel = UILabel()
    let awardLabelView = AwardLabelView(title: "初心者", backgroundColor: .systemGray)
    let fansNumberLabel = UILabel()
    let followingNumberLabel = UILabel()
    var userName = String()
    var awards = Int()
    var posts: [[String: Any]] = []
    let fansTextLabel = UILabel()
    let avatarImageView = UIImageView()
    let imagePicker = UIImagePickerController()
    var selectedImage: UIImage?
    let followingTextLabel = UILabel()
    let bottomSheetView = UIView()
    let backgroundView = UIView()
    let sheetHeight: CGFloat = 250
    let introductionLabel = UILabel()
    
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "個人"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, // 修改顏色
                .font: customFont // 設置字體
            ]
        }
        
        let navigateBtn = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), style: .plain, target: self, action: #selector(navigateToSettings))
        navigationItem.rightBarButtonItems = [navigateBtn]
        
        imagePicker.delegate = self
        setupTableView()
        setupRefreshControl()
        setupBottomSheet()
        guard let userId = userId else {
            return
        }
        
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userName = userName
                    self?.userNameLabel.text = userName
                }
                
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
                if let followers = data["followers"] as? [String] {
                    self?.fansNumberLabel.text = "粉絲人數：\(String(followers.count))"
                }
                
                if let followings = data["following"] as? [String] {
                    self?.followingNumberLabel.text = String(followings.count)
                }
                
                if let region = data["region"] as? String,
                   let introduction = data["introduction"] as? String {
                    self?.introductionLabel.text = introduction
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
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
        self.loadUserPosts()
        loadUserDataFromUserDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        guard let userId = userId else {
            return
        }
        
        // 每次頁面將要顯示時都重新加載資料
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userName = userName
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
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
        
        // 重新檢查每個 cell 的收藏狀態並更新
        for (index, post) in posts.enumerated() {
            guard let postId = post["id"] as? String else { continue }
            
            FirebaseManager.shared.isContentBookmarked(forUserId: userId, id: postId) { [weak self] isBookmarked in
                guard let cell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? UserTableViewCell else { return }
                cell.collectButton.isSelected = isBookmarked
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
        loadUserPosts()
    }
    
    @objc func navigateToSettings() {
        let settingsViewController = SettingsViewController()
        settingsViewController.title = "設定"
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    @objc func updateAwardTitle(_ notification: Notification) {
        if let userInfo = notification.userInfo, let newTitle = userInfo["title"] as? String {
            awardLabelView.updateTitle("\(newTitle)")
        }
    }
    
    func setupBottomSheet() {
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
        
        // 在選單視圖內部添加按鈕（這裡根據需要添加自訂按鈕）
        let deleteButton = createButton(title: "刪除貼文")
        let impeachButton = createButton(title: "檢舉貼文")
        let blockButton = createButton(title: "封鎖用戶")
        let cancelButton = createButton(title: "取消", textColor: .red)
        
        deleteButton.addTarget(self, action: #selector(deletePost), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [deleteButton, impeachButton, blockButton, cancelButton])
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
    
    @objc func deletePost(_ sender: UIButton) {
        let post = posts[sender.tag]
        guard let postId = post["id"] as? String else {
            return
        }
        
        let alert = UIAlertController(title: "確認刪除", message: "你確定要刪除這篇貼文嗎？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "刪除", style: .destructive, handler: { [weak self] _ in
            
            Firestore.firestore().collection("posts").document(postId).delete { error in
                if let error = error {
                    
                } else {
                    self?.posts.remove(at: sender.tag)
                    self?.tableView.deleteRows(at: [IndexPath(row: sender.tag, section: 0)], with: .fade)
                    self?.dismissBottomSheet()
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func createButton(title: String, textColor: UIColor = .black) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .clear
        return button
    }
    
    // 點擊 moreButton 呼叫此方法顯示選單
    func showBottomSheet(at indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        // 顯示彈窗
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: self.view.frame.height - self.sheetHeight, width: self.view.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 1
        }
        
        // 傳遞 IndexPath 到刪除按鈕
        let deleteButton = bottomSheetView.viewWithTag(1001) as? UIButton
        deleteButton?.addTarget(self, action: #selector(deletePost(_:)), for: .touchUpInside)
        deleteButton?.tag = indexPath.row  // 使用 `tag` 傳遞行號
    }
    
    @objc func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 0
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
                    self?.userName = userName
                    self?.userNameLabel.text = userName
                }
                
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
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
        
        loadUserPosts()
        
        // 結束刷新
        DispatchQueue.main.async {
            self.tableView.mj_header?.endRefreshing()
        }
    }
    
    func navigateToLoginScreen() {
        let loginVC = LoginViewController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: loginVC)
            window.makeKeyAndVisible()
        }
    }
    
    func loadUserDataFromUserDefaults() {
        if let savedUserName = UserDefaults.standard.string(forKey: "userName"),
           let savedUserId = UserDefaults.standard.string(forKey: "userId"),
           let savedEmail = UserDefaults.standard.string(forKey: "email") {
            
            self.userName = savedUserName
            self.userNameLabel.text = savedUserName
            
        } else {
        }
    }
    
    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let avatarUrl = URL(string: urlString)
        
        avatarImageView.kf.setImage(with: avatarUrl, placeholder: UIImage(named: "placeholder"), options: [
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ], completionHandler: { result in
            switch result {
            case .success(let value): break
            case .failure(let error):
                print("圖片加載失敗: \(error.localizedDescription)")
            }
        })
    }
}

extension UserViewController: UITableViewDelegate, UITableViewDataSource {
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        tableView.snp.makeConstraints { make in
            make.width.equalTo(view).multipliedBy(0.9)
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
        
        setupHeaderView()
    }
    
    func setupHeaderView() {
        
        headerView.backgroundColor = .systemGray5
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 280)
        headerView.layer.cornerRadius = 20  // 設置所需的圓角半徑
        headerView.layer.masksToBounds = true
        headerView.addSubview(userNameLabel)
        headerView.addSubview(awardLabelView)
        
        avatarImageView.backgroundColor = .blue
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)
        headerView.addSubview(fansTextLabel)
        headerView.addSubview(followingTextLabel)
        headerView.addSubview(fansNumberLabel)
        headerView.addSubview(followingNumberLabel)
        headerView.addSubview(introductionLabel)
        setupFollowersAndFollowing()
        setupLabel()
        
        introductionLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
            make.leading.equalTo(avatarImageView).offset(8)
            make.trailing.equalTo(headerView).offset(-16)
            make.height.equalTo(70)
        }
        
        let followingStackView = UIStackView(arrangedSubviews: [followingNumberLabel, followingTextLabel])
        followingStackView.axis = .vertical
        followingStackView.alignment = .center
        followingStackView.spacing = 0
        headerView.addSubview(followingStackView)
        
        let mapButton = UIButton()
        mapButton.setImage(UIImage(systemName: "map"), for: .normal) // 設置圖標
        mapButton.backgroundColor = .deepBlue
        mapButton.tintColor = .white
        mapButton.addTarget(self, action: #selector(handleMapButtonTapped), for: .touchUpInside)
        headerView.addSubview(mapButton)
        
        let awardsButton = UIButton()
        awardsButton.setImage(UIImage(systemName: "trophy"), for: .normal) // 設置圖標
        awardsButton.tintColor = .white
        awardsButton.backgroundColor = .deepBlue
        awardsButton.addTarget(self, action: #selector(handleAwardsButtonTapped), for: .touchUpInside)
        headerView.addSubview(awardsButton)
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(8)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.height.equalTo(50)
        }
        
        awardLabelView.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
            make.height.equalTo(24)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(headerView).offset(16)
        }
        
        avatarImageView.layer.cornerRadius = 50
        
        awardsButton.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView)
            make.trailing.equalTo(headerView.snp.trailing).offset(-16)
            make.width.height.equalTo(40)
        }
        awardsButton.layer.cornerRadius = 20
        
        mapButton.snp.makeConstraints { make in
            make.bottom.equalTo(awardsButton)
            make.trailing.equalTo(awardsButton.snp.leading).offset(-8)
            make.width.height.equalTo(40) // 設置大小
        }
        mapButton.layer.cornerRadius = 20
        
        let fansStackView = UIStackView(arrangedSubviews: [fansNumberLabel, fansTextLabel])
        fansStackView.axis = .vertical
        fansStackView.alignment = .center
        fansStackView.spacing = 0
        headerView.addSubview(fansStackView)
        
        fansStackView.snp.makeConstraints { make in
            make.top.equalTo(introductionLabel.snp.bottom).offset(20)
            make.centerX.equalTo(avatarImageView) // 垂直居中在 avatarImageView
        }
        
        followingStackView.snp.makeConstraints { make in
            make.top.equalTo(introductionLabel.snp.bottom).offset(20)
            make.leading.equalTo(fansStackView.snp.trailing).offset(40) // 與 followers 保持一定間隔
        }
        
        let fansTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFans))
        fansStackView.addGestureRecognizer(fansTapGesture)
        fansStackView.isUserInteractionEnabled = true
        
        let followingTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFollowing))
        followingStackView.addGestureRecognizer(followingTapGesture)
        followingStackView.isUserInteractionEnabled = true
        
        tableView.tableHeaderView = headerView
        
    }
    
    func setupLabel() {
        
        userNameLabel.text = "新用戶"
        userNameLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 24)
        userNameLabel.textColor = .deepBlue
        introductionLabel.numberOfLines = 3
        introductionLabel.lineSpacing = 6
        introductionLabel.font = UIFont(name: "NotoSerifHK-SemiBold", size: 16)
        introductionLabel.textColor = .darkGray
    }
    
    func setupFollowersAndFollowing() {
        
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
    }
    
    @objc func didTapFans() {
        let userListVC = UserListViewController()
            userListVC.isShowingFollowers = true
            userListVC.userId = self.userId
            navigationController?.pushViewController(userListVC, animated: true)
    }

    @objc func didTapFollowing() {
        let userListVC = UserListViewController()
            userListVC.isShowingFollowers = false // 表示要显示关注列表
            userListVC.userId = self.userId
            navigationController?.pushViewController(userListVC, animated: true)
    }
    
    @objc func handleMapButtonTapped() {
        
        let mapViewController = MapViewController()
        self.navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    @objc func handleAwardsButtonTapped() {
        
        let awardsViewController = AwardsViewController()
        self.navigationController?.pushViewController(awardsViewController, animated: true)
    }
    
    // UITableViewDataSource - 設定 cell 的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    // UITableViewDataSource - 設定每個 cell 的樣式
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        
        guard let cell = cell else { return UITableViewCell() }
        
        let post = posts[indexPath.row]
        let title = post["title"] as? String ?? "無標題"
        let content = post["content"] as? String ?? "no text"
        
        // 設置 cell 的文章標題
        cell.titleLabel.text = title
        cell.contentLabel.text = content
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        // 檢查按讚狀態
        let postId = post["id"] as? String ?? ""
        
        cell.configurePhotoStackView(with: post["photoUrls"] as? [String] ?? [])
        cell.likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        cell.configureMoreButton { [weak self] in
            self?.showBottomSheet(at: indexPath)
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
                    // 使用 Kingfisher 加載圖片到 avatarImageView
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
    
    func loadUserPosts() {
        FirebaseManager.shared.loadSpecifyUserPost(forUserId: userId ?? "") { [weak self] postsArray in
            guard let self = self else { return }
            self.posts = postsArray.sorted(by: { (post1, post2) -> Bool in
                if let createdAt1 = post1["createdAt"] as? Timestamp,
                   let createdAt2 = post2["createdAt"] as? Timestamp {
                    return createdAt1.dateValue() > createdAt2.dateValue()
                }
                return false
            })
            self.tableView.reloadData()
        }
    }
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            let postId = post["id"] as? String ?? ""
            
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
}
