//  PostViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

class PostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let db = Firestore.firestore()
    
    let titleTextField = UITextField()
    let contentTextView = UITextView()
    let postButton = UIButton(type: .system)
    var selectedTrip: Trip?
    var sharedImage: UIImage?
    let dropdownButton = UIButton(type: .system)
    let dropdownTableView = UITableView()
    var isDropdownVisible = false // 用來記錄下拉選單的狀態
    var dropdownHeightConstraint: Constraint?
    var tripsArray = [Trip]()
    var tripId = String()
    
    var postButtonAction: (() -> Void)?
    
    let imageButton = UIButton(type: .system) // 用來選擇圖片的按鈕
    var selectedImage: UIImage? // 儲存選擇的圖片
    var imageUrl: String? // 儲存圖片上傳後的下載 URL
    let avatarImageView = UIImageView()
    var selectedImages = [UIImage]() // 用來存儲選擇的圖片
    let imagesStackView = UIStackView() // StackView 用來顯示縮圖
    var photoUrls = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        navigationController?.navigationBar.tintColor = UIColor.deepBlue
        navigationItem.backButtonTitle = ""
        
        setupUI()
        setupDropdownTableView()
        
        self.navigationItem.largeTitleDisplayMode = .never
        let postButtonItem = UIBarButtonItem(title: "發文", style: .done, target: self, action: #selector(handlePostAction))
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        loadAvatarImageForPostView(userId: userId)
        postButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = postButtonItem
        
        if let trip = selectedTrip {
            var title = String()
            self.tripId = trip.id
            FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                title = poem.title
                self.dropdownButton.setTitle(title, for: .normal)
            }
            
        }
        loadTripsData(userId: userId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        resetPostForm()
        if let sharedImage = sharedImage {
                addImageToStackView(sharedImage) // 將分享的圖片添加到 StackView
            }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc func handlePostAction() {
        saveData()          // 執行保存操作
        backToLastPage()    // 返回上一頁
    }
    
    func addImageToStackView(_ image: UIImage) {
        // 添加圖片到已選圖片數組
        selectedImages.append(image)
        
        // 創建一個 UIView 作為圖片和按鈕的容器
        let imageContainer = UIView()
        imagesStackView.addArrangedSubview(imageContainer)
        
        // 創建縮圖
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageContainer.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // 讓 imageView 填滿容器
            make.width.height.equalTo(60) // 設置固定大小
        }
        
        // 为每张图片添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)

        // 創建一個 "叉叉" 按鈕
        let removeButton = UIButton(type: .custom)
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = .gray
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 12
        removeButton.clipsToBounds = true
        imageContainer.addSubview(removeButton)
        
        removeButton.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.top).offset(-8)  // 相對於父視圖的右上角
            make.trailing.equalTo(imageContainer.snp.trailing).offset(8)
            make.width.height.equalTo(24)
        }
        
        // 設置按鈕的點擊事件來移除圖片
        removeButton.addTarget(self, action: #selector(removeSelectedImage(_:)), for: .touchUpInside)
        removeButton.tag = selectedImages.count - 1  // 標記此按鈕，對應圖片位置
    }
    
    @objc func handleImageTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedImageView = gesture.view as? UIImageView,
              let tappedIndex = imagesStackView.arrangedSubviews.firstIndex(where: { $0.subviews.contains(tappedImageView) }) else {
            return
        }

        let fullScreenVC = FullScreenImageViewController()
        fullScreenVC.images = selectedImages // 将所有选中的图片传递过去
        fullScreenVC.startingIndex = tappedIndex // 设置从点击的图片开始展示

        navigationController?.pushViewController(fullScreenVC, animated: true)
    }


    func setupUI() {
        view.addSubview(contentTextView)
        view.addSubview(titleTextField)
        view.addSubview(imageButton)
        view.addSubview(imagesStackView)
        
        imagesStackView.axis = .horizontal
        imagesStackView.spacing = 8
        imagesStackView.alignment = .center
        imagesStackView.distribution = .fillEqually
        
        imagesStackView.snp.makeConstraints { make in
            make.leading.equalTo(imageButton.snp.trailing).offset(12) // 與 contentTextView 左對齊
            make.centerY.equalTo(imageButton)
            make.height.equalTo(60)
            make.trailing.equalTo(contentTextView)
        }
        
        avatarImageView.image = UIImage(named: "user-placeholder")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 27
        avatarImageView.clipsToBounds = true
        view.addSubview(avatarImageView)
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(54)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
        }
        
        contentTextView.text = ""
        titleTextField.text = ""
        
        contentTextView.backgroundColor = .systemGray5
        titleTextField.backgroundColor = .systemGray5
        titleTextField.layer.cornerRadius = 15
        dropdownButton.setTitle("choose trip", for: .normal)
        dropdownButton.backgroundColor = .deepBlue
        dropdownButton.setTitleColor(.white, for: .normal)
        dropdownButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        dropdownButton.layer.cornerRadius = 15
        view.addSubview(dropdownButton)
        
        dropdownButton.snp.makeConstraints { make in
            make.centerY.equalTo(avatarImageView) // 設置在 titleTextField 下方
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.trailing.equalTo(titleTextField)
            make.height.equalTo(50) // 高度 50 點
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(dropdownButton.snp.bottom).offset(12)
            make.height.equalTo(50)
            make.width.equalTo(view).multipliedBy(0.9)
            make.centerX.equalTo(view)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(12)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(view).multipliedBy(0.5)
            make.centerX.equalTo(view)
        }
        
        contentTextView.layer.cornerRadius = 15
        
        imageButton.setTitle("+ 新增相片", for: .normal)
        imageButton.setTitleColor(.deepBlue, for: .normal)
        imageButton.layer.borderWidth = 1
        imageButton.layer.borderColor = UIColor.deepBlue.cgColor
        imageButton.layer.cornerRadius = 15
        view.addSubview(imageButton)
        
        imageButton.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(16) // 設置在 contentTextView 下方
            make.leading.equalTo(contentTextView) // 與 contentTextView 左對齊
            make.width.equalTo(120) // 寬度 150 點
            make.height.equalTo(60) // 高度 50 點
        }
        
        imageButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        
        // 如果選擇了圖片，則顯示圖片
        if let selectedImage = selectedImage {
            let imageView = UIImageView(image: selectedImage)
            view.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.top.equalTo(imageButton.snp.bottom).offset(20)  // 距離 imageButton 底部 20 點
                make.centerX.equalTo(view)  // 水平方向居中
                make.width.height.equalTo(150)  // 設定圖片的寬度與高度為 150 點
            }
        }
        
        contentTextView.font = UIFont.systemFont(ofSize: 20)
        postButton.setTitle("發文", for: .normal)
        postButton.addTarget(self, action: #selector(saveData), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(backToLastPage), for: .touchUpInside)
        
        postButton.isEnabled = false
        
        titleTextField.delegate = self
        contentTextView.delegate = self
    }
    
    func loadAvatarImageForPostView(userId: String) {
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
            case .failure(let error):
                print("無法加載大頭貼: \(error.localizedDescription)")
            }
        }
    }
    
    // 加載圖片的通用方法
    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"), options: [
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ], completionHandler: { result in
            switch result {
            case .success(let value):
                print("圖片加載成功: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("圖片加載失敗: \(error.localizedDescription)")
            }
        })
    }
    
    func savePostData(userId: String, title: String, content: String, photoUrls: [String]) {
        let posts = Firestore.firestore().collection("posts")
        let document = posts.document()
        
        let data = [
            "id": document.documentID,
            "userId": userId,
            "title": title,
            "content": content,
            "photoUrls": photoUrls, // 儲存圖片的 URLs 到 Firestore
            "createdAt": Date(),
            "bookmarkAccount": [String](),
            "likesAccount": [String](),
            "tripId": tripId
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                print("發文失敗: \(error.localizedDescription)")
            } else {
            }
        }
    }
    
    @objc func backToLastPage() {
        titleTextField.text = ""
        contentTextView.text = ""
        postButtonAction?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func toggleDropdown() {
        isDropdownVisible.toggle() // 切換下拉選單的狀態
        
        if isDropdownVisible {
            dropdownTableView.isHidden = false
            dropdownHeightConstraint?.update(offset: CGFloat(tripsArray.count * 44))
        } else {
            dropdownHeightConstraint?.update(offset: 0)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func loadTripsData(userId: String) {
        self.tripsArray.removeAll()
        
        FirebaseManager.shared.loadBookmarkTripIDs(forUserId: userId) { [weak self] tripIds in
            guard let self = self else { return }
            
            if !tripIds.isEmpty {
                FirebaseManager.shared.loadBookmarkedTrips(tripIds: tripIds) { filteredTrips in
                    self.tripsArray = filteredTrips
                    self.dropdownTableView.reloadData()
                }
            } else {
                self.dropdownTableView.reloadData()
            }
        }
    }
}

extension PostViewController {
    
    @objc func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            // 檢查是否已經有 4 張圖片
            if selectedImages.count >= 4 {
                picker.dismiss(animated: true, completion: nil)
                return
            }
            
            // 添加圖片到已選圖片數組
            selectedImages.append(image)
            
            // 創建一個 UIView 作為圖片和按鈕的容器
            let imageContainer = UIView()
            imagesStackView.addArrangedSubview(imageContainer)
            
            // 創建縮圖
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageContainer.addSubview(imageView)
            
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview() // 讓 imageView 填滿容器
                make.width.height.equalTo(60) // 設置固定大小
            }
            
            // 創建一個 "叉叉" 按鈕
            let removeButton = UIButton(type: .custom)
            removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            removeButton.tintColor = .gray
            removeButton.backgroundColor = .white
            removeButton.layer.cornerRadius = 12
            removeButton.clipsToBounds = true
            imageContainer.addSubview(removeButton)
            
            removeButton.snp.makeConstraints { make in
                make.top.equalTo(imageContainer.snp.top).offset(-8)  // 相對於父視圖的右上角
                make.trailing.equalTo(imageContainer.snp.trailing).offset(8)
                make.width.height.equalTo(24)
            }
            
            // 設置按鈕的點擊事件來移除圖片
            removeButton.addTarget(self, action: #selector(removeSelectedImage(_:)), for: .touchUpInside)
            removeButton.tag = selectedImages.count - 1  // 標記此按鈕，對應圖片位置
            
            // 將圖片轉換成 JPEG 格式的 Data
            guard let imageData = image.jpegData(compressionQuality: 0.75) else {
                picker.dismiss(animated: true, completion: nil)
                return
            }
            
            // 開始上傳圖片
            uploadImageToFirebase(imageData) { [weak self] imageUrl in
                if let imageUrl = imageUrl {
                    // 儲存每張圖片的下載 URL 到陣列或處理邏輯中
                    self?.imageUrl = imageUrl
                } else {
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func removeSelectedImage(_ sender: UIButton) {
        let index = sender.tag
        
        // 移除選中的圖片
        selectedImages.remove(at: index)
        
        // 移除對應的 ImageView
        imagesStackView.arrangedSubviews[index].removeFromSuperview()
        
        // 更新剩餘圖片的標籤，以確保正確對應
        for (num, subview) in imagesStackView.arrangedSubviews.enumerated() {
            if let button = subview.subviews.compactMap({ $0 as? UIButton }).first {
                button.tag = num
            }
        }
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("postImages/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(nil)
            } else {
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("無法獲取下載 URL: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        completion(url?.absoluteString)
                    }
                }
            }
        }
    }
    
    func uploadImageToFirebase(_ imageData: Data, completion: @escaping (String?) -> Void) {
        // 初始化 storageRef
        let storageRef = Storage.storage().reference()  // 修正：確保每次上傳前正確初始化
        
        // 上傳圖片到指定的路徑
        let imageRef = storageRef.child("postImages/\(UUID().uuidString).jpg")
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("上傳圖片失敗: \(error.localizedDescription)")
                completion(nil)
            } else {
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("無法獲取下載 URL: \(error.localizedDescription)")
                        completion(nil)
                    } else if let downloadURL = url {
                        print("圖片成功上傳，URL: \(downloadURL)")
                        completion(downloadURL.absoluteString)
                    }
                }
            }
        }
    }
    
    // 上傳多張圖片到 Firebase 並返回 URLs
    func uploadImagesToFirebase(completion: @escaping ([String]?) -> Void) {
        let group = DispatchGroup() // 使用 DispatchGroup 來確保所有圖片都上傳完畢
        var uploadedUrls = [String]()
        
        for image in selectedImages {
            guard let imageData = image.jpegData(compressionQuality: 0.75) else {
                print("無法壓縮圖片")
                completion(nil)
                return
            }
            
            group.enter() // 開始上傳圖片
            uploadImageToFirebase(imageData) { imageUrl in
                if let imageUrl = imageUrl {
                    uploadedUrls.append(imageUrl)
                } else {
                }
                group.leave() // 圖片上傳結束
            }
        }
        
        group.notify(queue: .main) {
            // 當所有圖片上傳完畢後，將 URLs 傳遞出去
            completion(uploadedUrls)
        }
    }
    
    @objc func saveData() {
        guard let title = titleTextField.text, let content = contentTextView.text else { return }
        
        // 從 UserDefaults 中獲取 userId
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        uploadImagesToFirebase { [weak self] urls in
            guard let self = self, let urls = urls else {
                return
            }
            
            self.photoUrls = urls // 儲存圖片 URLs
            self.savePostData(userId: userId, title: title, content: content, photoUrls: urls)
        }
    }
}

extension PostViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupDropdownTableView() {
        dropdownTableView.delegate = self
        dropdownTableView.dataSource = self
        dropdownTableView.isHidden = true
        dropdownTableView.register(UITableViewCell.self, forCellReuseIdentifier: "dropdownCell")
        view.addSubview(dropdownTableView)
        
        dropdownTableView.snp.makeConstraints { make in
            make.top.equalTo(dropdownButton.snp.bottom)
            make.leading.trailing.equalTo(dropdownButton)
            dropdownHeightConstraint = make.height.equalTo(0).constraint
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tripsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dropdownCell", for: indexPath)
        
        let trip = tripsArray[indexPath.row]
        
        FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
            DispatchQueue.main.async {
                cell.textLabel?.text = poem.title
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let trip = tripsArray[indexPath.row]
        
        FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
            DispatchQueue.main.async {
                self.dropdownButton.setTitle(poem.title, for: .normal)
            }
        }
        
        tripId = trip.id
        postButton.isEnabled = true
        isDropdownVisible = false
        dropdownHeightConstraint?.update(offset: 0)
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        validateInputs(title: titleTextField.text ?? "", content: contentTextView.text)
    }
    
}

extension PostViewController: UITextFieldDelegate, UITextViewDelegate {
    
    // 當 TextField 文字改變時觸發
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 獲取更新後的文字
        let updatedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        validateInputs(title: updatedText, content: contentTextView.text)
        return true
    }
    
    // 當 TextView 文字改變時觸發
    func textViewDidChange(_ textView: UITextView) {
        validateInputs(title: titleTextField.text ?? "", content: textView.text)
    }
    
    func validateInputs(title: String, content: String) {
        let isTitleValid = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let isContentValid = !content.trimmingCharacters(in: .whitespaces).isEmpty
        let isTripSelected = !tripId.isEmpty
        
        // 如果所有條件都滿足，啟用發文按鈕
        navigationItem.rightBarButtonItem?.isEnabled = isTitleValid && isContentValid && isTripSelected
    }
    
    func resetPostForm() {
        // 清空文本输入
        titleTextField.text = ""
        contentTextView.text = ""
        // 重置按钮状态
        navigationItem.rightBarButtonItem?.isEnabled = false
        // 重置选择的图片
        selectedImages.removeAll()
        // 移除 StackView 中的所有图片视图
        imagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // 重置下拉菜单选择
        dropdownButton.setTitle("選擇行程", for: .normal)
        tripId = ""
        // 重置下拉菜单的显示状态
        isDropdownVisible = false
        dropdownHeightConstraint?.update(offset: 0)
        dropdownTableView.reloadData()
    }
}
