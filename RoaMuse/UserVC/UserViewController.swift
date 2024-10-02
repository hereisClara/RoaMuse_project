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
    
    let tableView = UITableView()
    let userNameLabel = UILabel()
    let awardLabelView = AwardLabelView(title: "稱號：", backgroundColor: .systemGray)
    let fansLabel = UILabel()
    var userName = String()
    var awards = Int()
    var posts: [[String: Any]] = []
    
    let avatarImageView = UIImageView()
    let imagePicker = UIImagePickerController()
    var selectedImage: UIImage?
    
    let bottomSheetView = UIView()
    let backgroundView = UIView() // 半透明背景
    let sheetHeight: CGFloat = 250 // 選單高度
    
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "個人"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, // 修改顏色
                .font: customFont // 設置字體
            ]
        }

        
        imagePicker.delegate = self
        setupTableView()
        setupRefreshControl()
        setupBottomSheet()
        guard let userId = userId else {
            print("未找到 userId，請先登入")
            return
        }
        
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userName = userName
                    self?.userNameLabel.text = userName
                }
                
                // 顯示 avatar 圖片
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
                if let followers = data["followers"] as? [String] {
                    self?.fansLabel.text = "粉絲人數：\(String(followers.count))"
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary))
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
        avatarImageView.isUserInteractionEnabled = true
        
        FirebaseManager.shared.loadAwardTitle(forUserId: userId) { [weak self] result in
            switch result {
            case .success(let awardTitle):
                DispatchQueue.main.async {
                    self?.awardLabelView.updateTitle("稱號：\(awardTitle)")
                }
            case .failure(let error):
                print("無法加載稱號: \(error.localizedDescription)")
            }
        }
        
        self.loadUserPosts()
        setupLogoutButton()
        loadUserDataFromUserDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let userId = userId else {
            print("未找到 userId，請先登入")
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
                    self?.fansLabel.text = "粉絲人數：\(String(followers.count))"
                }
                
                // 顯示 avatar 圖片
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
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
        
        FirebaseManager.shared.loadAwardTitle(forUserId: userId) { [weak self] result in
            switch result {
            case .success(let awardTitle):
                DispatchQueue.main.async {
                    self?.awardLabelView.updateTitle("稱號：\(awardTitle)")
                }
            case .failure(let error):
                print("無法加載稱號: \(error.localizedDescription)")
            }
        }
        
        // 每次頁面顯示時重新加載貼文數據
        loadUserPosts()
    }
    
    
    @objc func updateAwardTitle(_ notification: Notification) {
        if let userInfo = notification.userInfo, let newTitle = userInfo["title"] as? String {
            // 更新稱號 UI
            awardLabelView.updateTitle("稱號：\(newTitle)")
        }
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
            print("無法獲取貼文ID")
            return
        }
        
        let alert = UIAlertController(title: "確認刪除", message: "你確定要刪除這篇貼文嗎？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "刪除", style: .destructive, handler: { [weak self] _ in
            
            Firestore.firestore().collection("posts").document(postId).delete { error in
                if let error = error {
                    print("刪除貼文失敗: \(error.localizedDescription)")
                } else {
                    print("貼文已成功刪除")
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
    
    // 點擊背景或取消按鈕時呼叫此方法隱藏選單
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
                
                // 顯示 avatar 圖片
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
        }
        
        FirebaseManager.shared.loadAwardTitle(forUserId: userId) { [weak self] result in
            switch result {
            case .success(let awardTitle):
                DispatchQueue.main.async {
                    self?.awardLabelView.updateTitle("稱號：\(awardTitle)")
                }
            case .failure(let error):
                print("無法加載稱號: \(error.localizedDescription)")
            }
        }
        // 重新加載用戶貼文
        loadUserPosts()
        
        // 結束刷新
        DispatchQueue.main.async {
            self.tableView.mj_header?.endRefreshing()
        }
    }
    
    func setupLogoutButton() {
        let logoutButton = UIBarButtonItem(title: "登出", style: .plain, target: self, action: #selector(logout))
        self.navigationItem.rightBarButtonItem = logoutButton
    }
    
    @objc func logout() {
        // 清空 UserDefaults
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "email")
        
        print("已清空使用者資訊")
        
        // 跳轉到登入畫面
        navigateToLoginScreen()
    }
    
    func navigateToLoginScreen() {
        let loginVC = LoginViewController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: loginVC)
            window.makeKeyAndVisible()
        }
    }
    
    // 加載 UserDefaults 中的使用者資訊
    func loadUserDataFromUserDefaults() {
        if let savedUserName = UserDefaults.standard.string(forKey: "userName"),
           let savedUserId = UserDefaults.standard.string(forKey: "userId"),
           let savedEmail = UserDefaults.standard.string(forKey: "email") {
            
            self.userName = savedUserName
            self.userNameLabel.text = savedUserName
            // 這裡可以根據需要加載其他 UI 信息
            
            print("加載到的使用者資訊：\(savedUserName), \(savedUserId), \(savedEmail)")
        } else {
            print("沒有找到使用者資訊，請登入")
        }
    }
    
    @objc func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // 相片選擇完成後的回調
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            uploadImageToFirebaseStorage(image)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // 上傳圖片到 Firebase Storage
    func uploadImageToFirebaseStorage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("無法壓縮圖片")
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("上傳失敗: \(error.localizedDescription)")
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("無法獲取下載 URL: \(error.localizedDescription)")
                    return
                }
                
                if let downloadURL = url {
                    //                    print("圖片下載 URL: \(downloadURL.absoluteString)")
                    self.saveImageUrlToFirestore(downloadURL.absoluteString)
                }
            }
        }
    }
    
    // 將圖片的下載 URL 保存到 Firestore
    func saveImageUrlToFirestore(_ url: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId ?? "")  // 根據 userId 獲取使用者文件
        
        userRef.updateData([
            "photo": url
        ]) { error in
            if let error = error {
                print("保存到 Firestore 失敗: \(error.localizedDescription)")
            } else {
                self.loadAvatarImage(from: url)
            }
        }
    }
    
    
    // 取消選擇圖片
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
        
        // 註冊自定義 cell
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        tableView.backgroundColor = .clear
        // 設置代理和資料來源
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.snp.makeConstraints { make in
            make.width.equalTo(view).multipliedBy(0.9)
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
        
        // 設置 Header
        let headerView = UIView()
        headerView.backgroundColor = .systemGray5
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width , height: 210)
        headerView.layer.cornerRadius = 20  // 設置所需的圓角半徑
        headerView.layer.masksToBounds = true
        
        userNameLabel.text = "新用戶"
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(userNameLabel)
        
        headerView.addSubview(awardLabelView)
        
        avatarImageView.backgroundColor = .blue
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)
        
        fansLabel.text = "粉絲人數：0"
        fansLabel.font = UIFont.systemFont(ofSize: 16)
        headerView.addSubview(fansLabel)
        
        // 新增「行走地圖」按鈕
        let mapButton = UIButton(type: .system)
        mapButton.setTitle("行走地圖", for: .normal)
        mapButton.backgroundColor = .deepBlue
        mapButton.setTitleColor(.white, for: .normal)
        mapButton.layer.cornerRadius = 15
        mapButton.addTarget(self, action: #selector(handleMapButtonTapped), for: .touchUpInside)
        headerView.addSubview(mapButton)
        
        let awardsButton = UIButton(type: .system)
        awardsButton.setTitle("獎章成就", for: .normal)
        awardsButton.backgroundColor = .deepBlue
        awardsButton.setTitleColor(.white, for: .normal)
        awardsButton.layer.cornerRadius = 15
        awardsButton.addTarget(self, action: #selector(handleAwardsButtonTapped), for: .touchUpInside)
        headerView.addSubview(awardsButton)
        
        // 設置約束
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.height.equalTo(30)
        }
        
        awardLabelView.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
            make.height.equalTo(40)
            make.width.equalTo(180)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(110)
            make.top.equalTo(userNameLabel)
            make.leading.equalTo(headerView).offset(15)
        }
        
        avatarImageView.layer.cornerRadius = 55
        
        fansLabel.snp.makeConstraints { make in
            make.leading.equalTo(awardLabelView)
            make.bottom.equalTo(avatarImageView.snp.bottom)
        }
        
        // 設置「行走地圖」按鈕的約束
        mapButton.snp.makeConstraints { make in
            make.top.equalTo(fansLabel.snp.bottom).offset(24)
            make.leading.equalTo(avatarImageView)
            make.width.equalTo(headerView).multipliedBy(0.4)
            make.height.equalTo(40)
        }
        
        awardsButton.snp.makeConstraints { make in
            make.top.equalTo(fansLabel.snp.bottom).offset(24)
            make.leading.equalTo(mapButton.snp.trailing).offset(15)
            make.width.equalTo(headerView).multipliedBy(0.4)
            make.height.equalTo(40)
        }
        
        tableView.tableHeaderView = headerView
        
        let editButton = UIButton(type: .system)
        editButton.setImage(UIImage(systemName: "pencil.circle"), for: .normal) // 使用 SF Symbols 的鉛筆圖示
        editButton.tintColor = .deepBlue
        editButton.addTarget(self, action: #selector(editUserName), for: .touchUpInside)

        headerView.addSubview(editButton)

        // 設置 editButton 的約束
        editButton.snp.makeConstraints { make in
            make.leading.equalTo(userNameLabel.snp.trailing).offset(8) // 緊貼 userNameLabel 的右側
            make.centerY.equalTo(userNameLabel) // 與 userNameLabel 垂直居中對齊
            make.width.height.equalTo(30) // 設置固定的大小
        }

    }
    
    @objc func editUserName() {
        let alertController = UIAlertController(title: "編輯使用者名稱", message: "請輸入新的名稱", preferredStyle: .alert)
        
        // 在彈窗中添加一個文字輸入框
        alertController.addTextField { textField in
            textField.text = self.userNameLabel.text // 預設為當前的使用者名稱
        }
        
        // 添加「取消」按鈕
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // 添加「確認」按鈕
        let confirmAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            // 獲取輸入框中的文字
            if let newUserName = alertController.textFields?.first?.text, !newUserName.isEmpty {
                // 更新本地 userNameLabel
                self?.userNameLabel.text = newUserName
                self?.userName = newUserName
                // 上傳新的 userName 到 Firebase
                self?.updateUserNameInFirebase(newUserName)
            }
        }
        alertController.addAction(confirmAction)
        
        // 顯示彈窗
        present(alertController, animated: true, completion: nil)
    }

    func updateUserNameInFirebase(_ newUserName: String) {
        guard let userId = userId else {
            print("未找到 userId，無法更新使用者名稱")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.updateData(["userName": newUserName]) { error in
            if let error = error {
                print("更新使用者名稱失敗: \(error.localizedDescription)")
            } else {
                print("使用者名稱更新成功")
            }
        }
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
