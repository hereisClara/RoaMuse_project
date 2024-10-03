import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

import Foundation
import UIKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let tableView = UITableView()
    let avatarImageView = UIImageView()
    let userNameLabel = UILabel()
    let imagePicker = UIImagePickerController()
    
    // 設定選項數據
    let settingsOptions = ["封鎖名單", "刪除帳號", "登出"]
    
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "設定"
        
        imagePicker.delegate = self
        setupTableView()
        setupTableHeader()
        
        guard let userId = userId else {
            print("未找到 userId，請先登入")
            return
        }
        
        loadUserData(userId: userId)
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 註冊自定義的 cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 50
    }
    
    // 設置頭部視圖
    func setupTableHeader() {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 150)
        
        // 設置 avatarImageView
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.backgroundColor = .systemGray4
        avatarImageView.layer.cornerRadius = 45 // 圓形大頭貼
        headerView.addSubview(avatarImageView)
        
        // 設置相機圖示
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.circle"))
        cameraIcon.tintColor = .systemBlue
        cameraIcon.isUserInteractionEnabled = true
        headerView.addSubview(cameraIcon)
        
        // 設置用戶名稱
        userNameLabel.text = "使用者名稱"
        userNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        headerView.addSubview(userNameLabel)
        
        // 設置鉛筆圖示
        let editIcon = UIImageView(image: UIImage(systemName: "pencil.circle"))
        editIcon.tintColor = .systemBlue
        editIcon.isUserInteractionEnabled = true
        headerView.addSubview(editIcon)
        
        // 點擊大頭貼打開相片庫
        let avatarTapGesture = UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary))
        avatarImageView.addGestureRecognizer(avatarTapGesture)
        
        // 點擊鉛筆圖示編輯名稱
        let editTapGesture = UITapGestureRecognizer(target: self, action: #selector(editUserName))
        editIcon.addGestureRecognizer(editTapGesture)
        
        // 設置佈局
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        editIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            avatarImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 90),
            avatarImageView.heightAnchor.constraint(equalToConstant: 90),
            
            cameraIcon.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            cameraIcon.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            cameraIcon.widthAnchor.constraint(equalToConstant: 25),
            cameraIcon.heightAnchor.constraint(equalToConstant: 25),
            
            userNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 20),
            userNameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            
            editIcon.leadingAnchor.constraint(equalTo: userNameLabel.trailingAnchor, constant: 8),
            editIcon.centerYAnchor.constraint(equalTo: userNameLabel.centerYAnchor),
            editIcon.widthAnchor.constraint(equalToConstant: 25),
            editIcon.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        tableView.tableHeaderView = headerView
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        cell.textLabel?.text = settingsOptions[indexPath.row]
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedOption = settingsOptions[indexPath.row]
        
        if selectedOption == "登出" {
            handleLogout()
        } else if selectedOption == "刪除帳號" {
            handleDeleteAccount()
        }
    }
    
    // 處理登出邏輯
    func handleLogout() {
        let alert = UIAlertController(title: "登出", message: "你確定要登出嗎？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "登出", style: .destructive, handler: { _ in
            do {
                // 清空 UserDefaults
                UserDefaults.standard.removeObject(forKey: "userName")
                UserDefaults.standard.removeObject(forKey: "userId")
                UserDefaults.standard.removeObject(forKey: "email")
                
                print("已清空使用者資訊")
                // 跳轉到登入畫面
                self.navigateToLoginScreen()
            } catch let error {
                print("登出失敗: \(error.localizedDescription)")
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    // 處理刪除帳號邏輯
    func handleDeleteAccount() {
        let alert = UIAlertController(title: "刪除帳號", message: "你確定要刪除帳號嗎？此操作無法撤銷。", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "刪除", style: .destructive, handler: { _ in
            // 獲取當前用戶 ID
            guard let userId = self.userId else {
                print("無法獲取用戶ID")
                return
            }
            
            // 將用戶的狀態設為 0（軟刪除）
            self.softDeleteUser(userId: userId)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    // 軟刪除用戶（將狀態設為 0）
    func softDeleteUser(userId: String) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        // 更新 status 為 0，表示用戶帳號不可用
        userRef.updateData(["status": 0]) { error in
            if let error = error {
                print("無法將用戶設置為不可用: \(error.localizedDescription)")
            } else {
                print("用戶已成功設置為不可用")
                // 清空本地使用者資訊並登出
                self.handleLogout()
            }
        }
    }
    
    // 導航到登入畫面
    func navigateToLoginScreen() {
        let loginVC = LoginViewController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: loginVC)
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - 用戶資料加載
    func loadUserData(userId: String) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("加載用戶資料失敗: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                if let userData = document.data(),
                   let userName = userData["userName"] as? String,
                   let photoUrl = userData["photo"] as? String {
                    self.userNameLabel.text = userName
                    self.loadAvatarImage(from: photoUrl)
                }
            }
        }
    }
    
    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
    }
    
    // 開啟相片庫
    @objc func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // 照片選擇完成
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            avatarImageView.image = image
            uploadImageToFirebaseStorage(image)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // 上傳照片到 Firebase Storage
    func uploadImageToFirebaseStorage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("圖片壓縮失敗")
            return
        }
        
        let storageRef = Storage.storage().reference().child("avatars/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("上傳圖片失敗: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("無法獲取圖片 URL: \(error.localizedDescription)")
                    return
                }
                
                if let downloadURL = url {
                    self.saveImageUrlToFirestore(downloadURL.absoluteString)
                }
            }
        }
    }
    
    // 將圖片 URL 保存到 Firestore
    func saveImageUrlToFirestore(_ urlString: String) {
        guard let userId = userId else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.updateData(["photo": urlString]) { error in
            if let error = error {
                print("保存圖片 URL 失敗: \(error.localizedDescription)")
            } else {
                print("圖片 URL 成功保存")
            }
        }
    }
    
    // 編輯用戶名稱
    @objc func editUserName() {
        let alertController = UIAlertController(title: "編輯使用者名稱", message: "請輸入新的名稱", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = self.userNameLabel.text
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "確認", style: .default, handler: { [weak self] _ in
            if let newUserName = alertController.textFields?.first?.text, !newUserName.isEmpty {
                self?.userNameLabel.text = newUserName
                self?.updateUserNameInFirestore(newUserName)
            }
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // 更新 Firestore 中的用戶名稱
    func updateUserNameInFirestore(_ newUserName: String) {
        guard let userId = userId else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.updateData(["userName": newUserName]) { error in
            if let error = error {
                print("更新用戶名稱失敗: \(error.localizedDescription)")
            } else {
                print("用戶名稱更新成功")
            }
        }
    }
}

