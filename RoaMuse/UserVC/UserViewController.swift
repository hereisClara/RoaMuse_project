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
                    print(userName)
                    self?.userName = userName
                    self?.userNameLabel.text = userName
                }
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
            
            FirebaseManager.shared.countCompletedPlaces(userId: userId) { totalPlaces in
                print("使用者總共完成了 \(totalPlaces) 個地點")
                self?.awards = totalPlaces
                self?.awardsLabel.text = "打開卡片：\(String(self?.awards ?? 0))張"
            }
        }
        
        self.loadUserPosts()
    }
    
    func openPhotoLibrary() {
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
        let docData: [String: Any] = [
            "imageUrl": url,
            "uploadedAt": Timestamp(date: Date())
        ]
        db.collection("images").addDocument(data: docData) { error in
            if let error = error {
                print("保存到 Firestore 失敗: \(error.localizedDescription)")
            } else {
                print("圖片 URL 已保存到 Firestore")
            }
        }
    }
    
    // 取消選擇圖片
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
        headerView.addSubview(avatarImageView)
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell else {
            return UITableViewCell()
        }
        
        let post = posts[indexPath.row]
        let title = post["title"] as? String ?? "無標題"
        
        // 設置 cell 的文章標題
        cell.textLabel?.text = title
        cell.selectionStyle = .none
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
        return 180 // 設定 cell 高度
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
    
}
