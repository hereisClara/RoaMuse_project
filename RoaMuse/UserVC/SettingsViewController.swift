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
    var userName = String()
    let imagePicker = UIImagePickerController()
    var introduction = String()
    var region = String()
    var userGender: String?
    
    let settingsOptions = ["個人名稱", "性別", "個人簡介", "地區", "封鎖名單", "刪除帳號", "登出"]

    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = ""

        view.backgroundColor = UIColor.systemBackground
        self.navigationItem.largeTitleDisplayMode = .never
//        navigationController?.navigationBar.prefersLargeTitles = false
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let userId = userId else {
            print("未找到 userId，請先登入")
            return
        }
        
        loadUserData(userId: userId)
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        tableView.register(SettingDetailCell.self, forCellReuseIdentifier: "SettingDetailCell")
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    
    func setupTableHeader() {
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 120)
        
        // 設置 avatarImageView
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.backgroundColor = .systemGray4
        avatarImageView.layer.cornerRadius = 45
        headerView.addSubview(avatarImageView)
        
        // 設置相機圖示
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.circle"))
        cameraIcon.tintColor = .deepBlue
        cameraIcon.backgroundColor = .white
        cameraIcon.isUserInteractionEnabled = true
        cameraIcon.layer.cornerRadius = 12
        headerView.addSubview(cameraIcon)
        
        // 點擊大頭貼打開相片庫
        let avatarTapGesture = UITapGestureRecognizer(target: self, action: #selector(openPhotoLibrary))
        avatarImageView.addGestureRecognizer(avatarTapGesture)
        
        cameraIcon.snp.makeConstraints { make in
            make.trailing.equalTo(avatarImageView.snp.trailing)
            make.bottom.equalTo(avatarImageView.snp.bottom)
            make.width.height.equalTo(24)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.centerY.equalTo(headerView)
            make.centerX.equalTo(headerView)
            make.width.height.equalTo(90)
        }
        
        tableView.tableHeaderView = headerView
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return max(UITableView.automaticDimension, 60)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingDetailCell", for: indexPath) as? SettingDetailCell else {
            return UITableViewCell()
        }
        
        let settingOption = settingsOptions[indexPath.row]
        
        switch settingOption {
        case "個人名稱":
            cell.configureCell(title: "個人名稱", detail: userName ?? "使用者名稱")
        case "性別":
            cell.configureCell(title: "性別", detail: userGender ?? "選擇性別")
        case "個人簡介":
            cell.configureCell(title: "個人簡介", detail: introduction)
        case "地區":
            cell.configureCell(title: "地區", detail: region)
        case "封鎖名單":
            cell.configureCell(title: "封鎖名單", detail: "")
        case "刪除帳號":
            cell.configureCell(title: "刪除帳號", detail: "")
        case "登出":
            cell.configureCell(title: "登出", detail: "")
        default:
            break
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedOption = settingsOptions[indexPath.row]
        
        if selectedOption == "性別" {
            showGenderSelection()
        } else if selectedOption == "個人名稱" {
            editUserName()
        } else if selectedOption == "登出" {
            handleLogout()
        } else if selectedOption == "刪除帳號" {
            handleDeleteAccount()
        } else if selectedOption == "個人簡介" {
            let introVC = IntroductionViewController()
            introVC.currentBio = introduction
            introVC.delegate = self
            let navController = UINavigationController(rootViewController: introVC)
            self.present(navController, animated: true, completion: nil)
        } else if selectedOption == "地區" {
            let regionVC = RegionSelectionViewController()
            regionVC.delegate = self
            let navController = UINavigationController(rootViewController: regionVC)
            self.present(navController, animated: true, completion: nil)
        } else if selectedOption == "封鎖名單" {
            let blockVC = BlockedListViewController()
            navigationController?.pushViewController(blockVC, animated: true)
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
                   let photoUrl = userData["photo"] as? String,
                   let region = userData["region"] as? String,
                   let introduction = userData["introduction"] as? String,
                   let gender = userData["gender"] as? String {
                    self.userName = userName
                    self.introduction = introduction
                    self.region = region
                    self.userGender = gender
                    self.loadAvatarImage(from: photoUrl)
                }
                self.tableView.reloadData()
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
    
    func loadCurrentUserBio() {
        guard let userId = userId else { return }
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("加載個人簡介失敗: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                self.introduction = document.data()?["introduction"] as? String ?? ""
                self.region = document.data()?["region"] as? String ?? ""
            }
        }
    }
    
    func showGenderSelection() {
        let alertController = UIAlertController(title: "選擇性別", message: nil, preferredStyle: .actionSheet)
        
        let maleAction = UIAlertAction(title: "男性", style: .default) { _ in
            self.updateGender("男性")
        }
        
        let femaleAction = UIAlertAction(title: "女性", style: .default) { _ in
            self.updateGender("女性")
        }
        
        let otherAction = UIAlertAction(title: "其他", style: .default) { _ in
            self.updateGender("其他")
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(maleAction)
        alertController.addAction(femaleAction)
        alertController.addAction(otherAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func updateGender(_ gender: String) {
        self.userGender = gender
        guard let userId = userId else { return }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.updateData(["gender": gender]) { error in
            if let error = error {
                print("保存性別失敗: \(error.localizedDescription)")
            } else {
                print("性別保存成功")
                self.tableView.reloadData()
            }
        }
    }
}

extension SettingsViewController: IntroductionViewControllerDelegate {
    
    func introductionViewControllerDidSave(_ intro: String) {
        
            guard let userId = userId else { return }
            
            let userRef = Firestore.firestore().collection("users").document(userId)
            userRef.updateData(["introduction": intro]) { error in
                if let error = error {
                    print("保存個人簡介失敗: \(error.localizedDescription)")
                } else {
                    print("個人簡介保存成功")
                    self.tableView.reloadData()
            }
        }
    }
}

extension SettingsViewController: RegionSelectionDelegate {
    
    func didSelectRegion(_ region: String) {
            // 保存到 Firebase Firestore
            guard let userId = userId else { return }
            let userRef = Firestore.firestore().collection("users").document(userId)
            
            userRef.updateData(["region": region]) { error in
                if let error = error {
                    print("保存地區失敗: \(error.localizedDescription)")
                } else {
                    print("地區保存成功")
                    
                    self.tableView.reloadData()
                }
            }
        }
    
}
