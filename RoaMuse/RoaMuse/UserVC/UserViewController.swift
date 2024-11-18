import Foundation
import UIKit
import SnapKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher
import MJRefresh
import SideMenu

class UserViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var selectedIndexPath: IndexPath?
    let emptyStateLabel = UILabel()
    var isShowingFollowers: Bool = true
    var postsCount = Int()
    let postsNumberLabel = UILabel()
    let postsTextLabel = UILabel()
    let awardsButton = UIButton()
    let mapButton = UIButton()
    let regionLabelView = RegionLabelView(region: nil)
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
    let moreButton = UIButton()
    var isExpanded = false
    var userId: String? { return UserDefaults.standard.string(forKey: "userId") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "個人"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue,
                .font: customFont
            ]
        }
        navigationController?.navigationBar.tintColor = .deepBlue
        let navigateBtn = UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), style: .plain, target: self, action: #selector(navigateToSettings))
        navigationItem.rightBarButtonItems = [navigateBtn]
        imagePicker.delegate = self
        setupTableView()
        setupEmptyStateLabel()
        setupRefreshControl()
        setupBottomSheet()
        guard let userId = userId else { return }
        
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
        loadUserDataFromUserDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "個人"
        setupNavigationBarStyle()
        navigationController?.navigationBar.tintColor = .deepBlue
        
        guard let userId = userId else { return }
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadUserPosts()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeaderViewHeight()
    }
    
    private func setupNavigationBarStyle() {
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue,
                .font: customFont
            ]

            self.navigationItem.standardAppearance = navBarAppearance
            self.navigationItem.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    @objc func navigateToSettings() {
        let settingsViewController = SettingsViewController()
        settingsViewController.title = "設定"
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    func setupBottomSheet() {
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.frame = self.view.bounds
        backgroundView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        backgroundView.addGestureRecognizer(tapGesture)
        
        bottomSheetView.backgroundColor = .white
        bottomSheetView.layer.cornerRadius = 15
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        bottomSheetView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: sheetHeight)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(backgroundView)
            window.addSubview(bottomSheetView)
        }
        
        let deleteButton = createButton(title: "刪除貼文")
        deleteButton.tag = 1001
        deleteButton.addTarget(self, action: #selector(deletePost(_:)), for: .touchUpInside)
        
        let impeachButton = createButton(title: "檢舉貼文")
        let blockButton = createButton(title: "封鎖用戶")
        let cancelButton = createButton(title: "取消", textColor: .red)
        cancelButton.addTarget(self, action: #selector(dismissBottomSheet), for: .touchUpInside)
        
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
        guard let indexPath = self.selectedIndexPath else { return }
        let post = posts[indexPath.row]
        guard let postId = post["id"] as? String else { return }
        
        let alert = UIAlertController(title: "確認刪除", message: "你確定要刪除這篇貼文嗎？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "刪除", style: .destructive, handler: { [weak self] _ in
            Firestore.firestore().collection("posts").document(postId).delete { [weak self] error in
                if error == nil {
                    self?.handlePostDeletion(at: indexPath)
                } else {
                    print("刪除失敗: \(error?.localizedDescription ?? "未知錯誤")")
                }
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func handlePostDeletion(at indexPath: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismissBottomSheet()
            self.updateEmptyState()
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
    
    func showBottomSheet(at indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        
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
        
        DispatchQueue.main.async {
            self.tableView.mj_header?.endRefreshing()
        }
    }
    
    func loadUserDataFromUserDefaults() {
        if let savedUserName = UserDefaults.standard.string(forKey: "userName"),
           let savedUserId = UserDefaults.standard.string(forKey: "userId"),
           let savedEmail = UserDefaults.standard.string(forKey: "email") {
            
            self.userName = savedUserName
            self.userNameLabel.text = savedUserName
            
            FirebaseManager.shared.loadAwardTitle(forUserId: savedUserId) { (result: Result<(String, Int), Error>) in
                        switch result {
                        case .success(let (awardTitle, item)):
                            let title = awardTitle
                            self.awardLabelView.updateTitle(title)
                            DispatchQueue.main.async {
                                AwardStyleManager.updateTitleContainerStyle(
                                    forTitle: awardTitle, item: item, titleContainerView: self.awardLabelView,
                                    titleLabel: self.awardLabelView.titleLabel, dropdownButton: nil)
                            }
                        case .failure(let error):
                            print("獲取稱號失敗: \(error.localizedDescription)")
                        }
                    }
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 240
        tableView.layer.cornerRadius = 20
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
        headerView.layer.cornerRadius = 20
        headerView.layer.masksToBounds = true
        headerView.layer.borderColor = UIColor.deepBlue.cgColor
        headerView.layer.borderWidth = 2
        avatarImageView.image = UIImage(named: "user-placeholder")
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        [userNameLabel, awardLabelView, avatarImageView, fansTextLabel, followingTextLabel, fansNumberLabel,
         followingNumberLabel, introductionLabel, mapButton, awardsButton].forEach { headerView.addSubview($0) }
        
        setupFollowersAndFollowing()
        setupPostsStackView()
        setupLabel()
        
        let followingStackView = UIStackView(arrangedSubviews: [followingNumberLabel, followingTextLabel])
        followingStackView.axis = .vertical
        followingStackView.alignment = .center
        followingStackView.spacing = 0
        headerView.addSubview(followingStackView)
        
        mapButton.setImage(UIImage(systemName: "map"), for: .normal)
        mapButton.backgroundColor = .deepBlue
        mapButton.tintColor = .white
        mapButton.addTarget(self, action: #selector(handleMapButtonTapped), for: .touchUpInside)
        
        awardsButton.setImage(UIImage(systemName: "trophy"), for: .normal)
        awardsButton.tintColor = .white
        awardsButton.backgroundColor = .deepBlue
        awardsButton.addTarget(self, action: #selector(handleAwardsButtonTapped), for: .touchUpInside)
        
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
        
        headerView.addSubview(regionLabelView)
        
        regionLabelView.snp.makeConstraints { make in
            make.leading.equalTo(awardLabelView)
            make.height.equalTo(24)
            make.top.equalTo(awardLabelView.snp.bottom).offset(4)
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
            make.bottom.equalTo(awardsButton.snp.top).offset(-12)
            make.trailing.equalTo(awardsButton)
            make.width.height.equalTo(40)
        }
        mapButton.layer.cornerRadius = 20
        
        let fansStackView = UIStackView(arrangedSubviews: [fansNumberLabel, fansTextLabel])
        fansStackView.axis = .vertical
        fansStackView.alignment = .center
        fansStackView.spacing = 0
        headerView.addSubview(fansStackView)
        
        let postStackView = UIStackView(arrangedSubviews: [postsNumberLabel, postsTextLabel])
        postStackView.axis = .vertical
        postStackView.alignment = .center
        postStackView.spacing = 0
        headerView.addSubview(postStackView)
        
        introductionLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(22)
            make.leading.equalTo(headerView).offset(16)
            make.trailing.equalTo(headerView).offset(-16)
            make.bottom.equalTo(fansStackView.snp.top).offset(-16)
        }
        
        fansStackView.snp.makeConstraints { make in
            make.centerX.equalTo(headerView)
            make.bottom.equalTo(headerView.snp.bottom).offset(-16)
        }
        postStackView.snp.makeConstraints { make in
            make.centerY.equalTo(fansStackView)
            make.centerX.equalTo(fansStackView.snp.leading).offset(-80)
        }
        
        followingStackView.snp.makeConstraints { make in
            make.centerY.equalTo(fansStackView)
            make.centerX.equalTo(fansStackView.snp.trailing).offset(80)
        }
        let fansTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFans))
        fansStackView.addGestureRecognizer(fansTapGesture)
        fansStackView.isUserInteractionEnabled = true
        let followingTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapFollowing))
        followingStackView.addGestureRecognizer(followingTapGesture)
        followingStackView.isUserInteractionEnabled = true
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        tableView.tableHeaderView = headerView
    }
    
    func setupPostsStackView() {
        postsNumberLabel.text = String(postsCount)
        postsNumberLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        postsTextLabel.text = "Posts"
        postsTextLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 12)
        postsTextLabel.textColor = .gray
        postsTextLabel.textAlignment = .center
    }
    
    func setupLabel() {
        userNameLabel.text = "新用戶"
        userNameLabel.font = UIFont(name: "NotoSerifHK-Black", size: 22)
        userNameLabel.textColor = .deepBlue
        introductionLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        introductionLabel.numberOfLines = 0
        introductionLabel.textColor = .darkGray
        introductionLabel.lineBreakMode = .byTruncatingTail
        introductionLabel.setContentHuggingPriority(.required, for: .vertical)
        introductionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let lineHeight = actualLineHeight()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: introductionLabel.font!,
            .paragraphStyle: paragraphStyle
        ]
        let attributedText = NSAttributedString(string: introductionLabel.text ?? "", attributes: attributes)
        introductionLabel.attributedText = attributedText
    }
    
    func updateTableHeaderViewHeight() {
        guard let header = tableView.tableHeaderView else { return }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let newSize = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        var headerFrame = header.frame
        headerFrame.size.height = newSize.height
        header.frame = headerFrame
        tableView.tableHeaderView = header
    }
    
    func calculateIntroductionLabelHeight() -> CGFloat {
        let maxWidth = tableView.frame.width - 32
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attributes: [NSAttributedString.Key: Any] = [
            .font: introductionLabel.font!,
            .paragraphStyle: paragraphStyle
        ]
        let text = introductionLabel.text ?? ""
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
        return ceil(boundingRect.height)
    }
    
    func setupFollowersAndFollowing() {
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
    
    @objc func handleMapButtonTapped() {
        let menuController = MenuViewController()
        let mapVC = MapViewController()
        let sideMenuController = SideMenuController(contentViewController: mapVC, menuViewController: menuController)
        menuController.onSelectionConfirmed = { [weak self] selectedIndex in
            guard let self = self else { return }
            sideMenuController.hideMenu(animated: true) { _ in
                mapVC.loadCompletedPlacesAndAddAnnotations(selectedIndex: selectedIndex)
            }
        }
        SideMenuController.preferences.basic.direction = .right
        SideMenuController.preferences.basic.menuWidth = 280
        SideMenuController.preferences.basic.enablePanGesture = true
        navigationController?.pushViewController(sideMenuController, animated: true)
    }
    
    func handleLikeButtonTap(at indexPath: IndexPath, isLiked: Bool) {
        var post = posts[indexPath.row]
        var likesAccount = post["likesAccount"] as? [String] ?? []
        if isLiked {
            likesAccount.append(userId ?? "")
        } else {
            likesAccount.removeAll { $0 == userId }
        }
        post["likesAccount"] = likesAccount
        posts[indexPath.row] = post
        
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()
        }
    }
    
    @objc func handleAwardsButtonTapped() {
        let awardsViewController = AwardsViewController()
        self.navigationController?.pushViewController(awardsViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        guard let cell = cell else { return UITableViewCell() }
        cell.titleLabel.text = ""
        cell.contentLabel.text = ""
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
        let currentRow = indexPath.row
        cell.configureMoreButton { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: currentRow, section: indexPath.section)
            self.showBottomSheet(at: indexPath)
        }
        if let createdAtTimestamp = post["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        if let likesAccount = post["likesAccount"] as? [String] {
            cell.likeCountLabel.text = String(likesAccount.count)
            cell.likeButton.isSelected = likesAccount.contains(self.userId ?? "")
        } else {
            cell.likeCountLabel.text = "0"
            cell.likeButton.isSelected = false
        }

        if let bookmarkAccount = post["bookmarkAccount"] as? [String] {
            cell.collectButton.isSelected = bookmarkAccount.contains(self.userId ?? "")
        } else {
            cell.collectButton.isSelected = false
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
                                forTitle: awardTitle, item: item, titleContainerView: cell.awardLabelView,
                                titleLabel: cell.awardLabelView.titleLabel, dropdownButton: nil)
                        }
                    case .failure(let error):
                        print("獲取稱號失敗: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("加載用戶大頭貼失敗: \(error.localizedDescription)")
            }
        }
        
        cell.photoTappedHandler = { [weak self] index in
            guard let self = self else { return }
            let post = self.posts[indexPath.row]
            let photoUrls = post["photoUrls"] as? [String] ?? []
            self.showFullScreenImages(photoUrls: photoUrls, startingIndex: index)
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
                articleVC.photoUrls = post["photoUrls"] as? [String] ?? []
                if let createdAtTimestamp = post["createdAt"] as? Timestamp {
                    let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                    articleVC.articleDate = createdAtString
                }
                
                articleVC.authorId = post["userId"] as? String ?? ""
                articleVC.postId = post["id"] as? String ?? ""
                articleVC.bookmarkAccounts = post["bookmarkAccount"] as? [String] ?? []
                
                self.navigationController?.pushViewController(articleVC, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func loadUserPosts() {
        guard let userId = userId else { return }
        
        FirebaseManager.shared.db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error { return }
                guard let documents = snapshot?.documents else { return }
                
                self.posts = documents.map { document in
                    var postData = document.data()
                    postData["id"] = document.documentID 
                    return postData
                }
                
                self.posts.sort(by: { (post1, post2) -> Bool in
                    if let createdAt1 = post1["createdAt"] as? Timestamp,
                       let createdAt2 = post2["createdAt"] as? Timestamp {
                        return createdAt1.dateValue() > createdAt2.dateValue()
                    }
                    return false
                })
                
                DispatchQueue.main.async {
                    self.postsCount = self.posts.count
                    self.postsNumberLabel.text = String(self.postsCount)
                    UIView.performWithoutAnimation {
                        self.tableView.reloadData()
                        self.tableView.layoutIfNeeded()
                    }
                    self.updateEmptyState()
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
            handleLikeButtonTap(at: indexPath, isLiked: sender.isSelected)
            updateLikeStatus(postId: postId, isLiked: sender.isSelected)
        }
    }
    
    func updateLikeStatus(postId: String, isLiked: Bool) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        if isLiked {
            postRef.updateData([
                "likesAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error { }
            }
        } else {
            postRef.updateData([
                "likesAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error { }
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
                if let error = error { }
            }
        } else {
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error { }
            }
        }
    }
    
    func actualLineHeight() -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: introductionLabel.font!,
            .paragraphStyle: paragraphStyle
        ]
        
        let text = "A"
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let size = attributedText.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                                               options: .usesLineFragmentOrigin, context: nil).size
        return ceil(size.height)
    }
    
    func setupEmptyStateLabel() {
        emptyStateLabel.text = "現在還沒有日記"
        emptyStateLabel.textColor = .lightGray
        emptyStateLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
        
        view.insertSubview(emptyStateLabel, belowSubview: tableView)
        
        emptyStateLabel.snp.makeConstraints { make in
            make.centerX.equalTo(tableView)
            make.bottom.equalTo(view).offset(-100)
        }
    }
    
    func updateEmptyState() {
        let hasPosts = !posts.isEmpty
        emptyStateLabel.isHidden = hasPosts 
    }
    
    func showFullScreenImages(photoUrls: [String], startingIndex: Int) {
        let fullScreenVC = FullScreenImageViewController()
        let dispatchGroup = DispatchGroup()
        var images: [UIImage] = Array(repeating: UIImage(), count: photoUrls.count)
        
        for (index, urlString) in photoUrls.enumerated() {
            guard let url = URL(string: urlString) else { continue }
            
            dispatchGroup.enter()
            URLSession.shared.dataTask(with: url) { data, _, error in
                defer { dispatchGroup.leave() }
                if let error = error { return }
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
