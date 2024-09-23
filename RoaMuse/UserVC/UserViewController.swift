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

class UserViewController: UIViewController, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    let tableView = UITableView()
    let userNameLabel = UILabel()
    let awardsLabel = UILabel()
    var userName = String()
    var awards = Int()
    var posts: [[String: Any]] = []
    
    let avatarImageView = UIImageView()
    let imagePicker = UIImagePickerController()
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        imagePicker.delegate = self
        setupTableView()
        
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
            
            FirebaseManager.shared.countCompletedPlaces(userId: userId) { totalPlaces in
                self?.awards = totalPlaces
                self?.awardsLabel.text = "打開卡片：\(String(self?.awards ?? 0))張"
            }
        }
        
        self.loadUserPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 每次頁面將要顯示時都重新加載資料
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
            
            FirebaseManager.shared.countCompletedPlaces(userId: userId) { totalPlaces in
                self?.awards = totalPlaces
                self?.awardsLabel.text = "打開卡片：\(String(self?.awards ?? 0))張"
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
        
        // 每次頁面顯示時重新加載貼文數據
        loadUserPosts()
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
                    print("圖片下載 URL: \(downloadURL.absoluteString)")
                    self.saveImageUrlToFirestore(downloadURL.absoluteString)
                }
            }
        }
    }
    
    // 將圖片的下載 URL 保存到 Firestore
    func saveImageUrlToFirestore(_ url: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)  // 根據 userId 獲取使用者文件
        
        userRef.updateData([
            "photo": url
        ]) { error in
            if let error = error {
                print("保存到 Firestore 失敗: \(error.localizedDescription)")
            } else {
                print("圖片 URL 已保存到 Firestore")
                // 保存成功後，立即加載新圖片到 avatarImageView
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
                case .success(let value):
                    print("圖片成功加載: \(value.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("圖片加載失敗: \(error.localizedDescription)")
                }
            })
        }
    
    // 設置 TableView
    func setupTableView() {
        view.addSubview(tableView)
        
        // 註冊自定義 cell
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        
        // 設置代理和資料來源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 設置 Header
        let headerView = UIView()
        headerView.backgroundColor = .lightGray
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 120)
        
        userNameLabel.text = userName
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(userNameLabel)
        
        awardsLabel.text = "打開卡片：\(String(self.awards))張"
        awardsLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        headerView.addSubview(awardsLabel)
        
        avatarImageView.backgroundColor = .blue
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary))
        avatarImageView.addGestureRecognizer(tapGesture)  // 為 avatar 增加點擊手勢
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
        }
        
        awardsLabel.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(70)
            make.centerY.equalTo(headerView)
            make.leading.equalTo(headerView).offset(15)
        }
        
        tableView.tableHeaderView = headerView
        
        // 設置 TableView 大小等於 safeArea
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
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
        
        cell.likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == postId
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                // 更新 likeCountLabel
                DispatchQueue.main.async {
                    // 更新 likeCountLabel 和按鈕的選中狀態
                    cell.likeCountLabel.text = String(likesAccount.count)
                    cell.likeButton.isSelected = likesAccount.contains(userId) // 依據是否按讚來設置狀態
                    print("/////", likesAccount.contains(userId))
                }
            } else {
                // 如果沒有找到相應的貼文，或者 likesAccount 為空
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = "0"
                    cell.likeButton.isSelected = false // 依據狀態設置未選中
                }
            }
        }
        
        FirebaseManager.shared.fetchUserData(userId: userId) { result in
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
        FirebaseManager.shared.isContentBookmarked(forUserId: userId, id: postId) { isBookmarked in
            cell.collectButton.isSelected = isBookmarked
        }
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        let articleVC = ArticleViewController()
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                print("找到的 userName: \(userName)")
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
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
    
    // UITableViewDelegate - 設定 cell 高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250 // 設定 cell 高度
    }
    
    func loadUserPosts() {
        FirebaseManager.shared.loadSpecifyUserPost(forUserId: userId) { [weak self] postsArray in
            guard let self = self else { return }
            
            // 根據文章的 createdAt 時間戳排序
            self.posts = postsArray.sorted(by: { (post1, post2) -> Bool in
                if let createdAt1 = post1["createdAt"] as? Timestamp,
                   let createdAt2 = post2["createdAt"] as? Timestamp {
                    return createdAt1.dateValue() > createdAt2.dateValue()
                }
                return false
            })
            print("加載到的文章數據: \(self.posts)")
            // 重新載入表格數據
            self.tableView.reloadData()
        }
    }
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            let postId = post["id"] as? String ?? ""
            
            // 更新 Firebase 中的 like 狀態
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
                    print("按讚成功")
                }
            }
        } else {
            postRef.updateData([
                "likesAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消按讚失敗: \(error.localizedDescription)")
                } else {
                    print("取消按讚成功")
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
            
            // 更新 Firebase 中的收藏狀態
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
                    print("收藏成功")
                }
            }
        } else {
            postRef.updateData([
                "bookmarkAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消收藏失敗: \(error.localizedDescription)")
                } else {
                    print("取消收藏成功")
                }
            }
        }
    }
}
