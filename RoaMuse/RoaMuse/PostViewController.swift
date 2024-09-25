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

class PostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let db = Firestore.firestore()
    
    let titleTextField = UITextField()
    let contentTextView = UITextView()
    let postButton = UIButton(type: .system)
    
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
    
    var selectedImages = [UIImage]() // 用來存儲選擇的圖片
    let imagesStackView = UIStackView() // StackView 用來顯示縮圖
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        setupUI()
        setupDropdownTableView()
        
        let postButtonItem = UIBarButtonItem(title: "發文", style: .done, target: self, action: #selector(handlePostAction))
        
        postButtonItem.isEnabled = false
            navigationItem.rightBarButtonItem = postButtonItem
        
        // 從 UserDefaults 中讀取 userId
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("未找到 userId，請先登入")
            return
        }
        
        // 加載該 userId 對應的行程數據
        loadTripsData(userId: userId)
    }
    
    @objc func handlePostAction() {
        saveData()          // 執行保存操作
        backToLastPage()    // 返回上一頁
    }
    
    func setupUI() {
        view.addSubview(contentTextView)
        view.addSubview(titleTextField)
//        view.addSubview(postButton)
        
        view.addSubview(imageButton)
        
        view.addSubview(imagesStackView)
            
            imagesStackView.axis = .horizontal
            imagesStackView.spacing = 4
            imagesStackView.alignment = .center
            imagesStackView.distribution = .fillEqually
            
            imagesStackView.snp.makeConstraints { make in
                make.leading.equalTo(imageButton.snp.trailing).offset(12) // 與 contentTextView 左對齊
                make.centerY.equalTo(imageButton)
                make.height.equalTo(60) // 設置 StackView 高度
                make.trailing.equalTo(contentTextView)
            }
        
        let avatarView = UIView() // 新增的 avatar 方框
        avatarView.backgroundColor = .systemPink
        view.addSubview(avatarView)

        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(50) // 設置為正方形
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20) // 靠左邊 16 點
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16) // 頂部間距 16 點
        }
        
        contentTextView.text = ""
        titleTextField.text = ""
        
        contentTextView.backgroundColor = .systemGray5
        titleTextField.backgroundColor = .systemGray5
        dropdownButton.setTitle("選擇行程", for: .normal)
        dropdownButton.backgroundColor = .systemBlue
        dropdownButton.setTitleColor(.white, for: .normal)
        dropdownButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        view.addSubview(dropdownButton)

        dropdownButton.snp.makeConstraints { make in
            make.centerY.equalTo(avatarView) // 設置在 titleTextField 下方
            make.leading.equalTo(avatarView.snp.trailing).offset(16)
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
        
        imageButton.setTitle("+ 新增相片", for: .normal)
        imageButton.setTitleColor(.systemBlue, for: .normal)
        imageButton.layer.borderWidth = 1
        imageButton.layer.borderColor = UIColor.systemBlue.cgColor
        imageButton.layer.cornerRadius = 8
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
                print("最多只能選擇 4 張圖片")
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
            removeButton.tintColor = .white
            removeButton.backgroundColor = .red
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
                print("無法壓縮圖片")
                picker.dismiss(animated: true, completion: nil)
                return
            }
            
            // 開始上傳圖片
            uploadImageToFirebase(imageData) { [weak self] imageUrl in
                if let imageUrl = imageUrl {
                    // 儲存每張圖片的下載 URL 到陣列或處理邏輯中
                    self?.imageUrl = imageUrl
                    print("圖片上傳成功，下載 URL：\(imageUrl)")
                } else {
                    print("圖片上傳失敗")
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

    // 移除圖片的按鈕事件
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
            print("圖片壓縮失敗")
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
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
    
    @objc func saveData() {
        guard let title = titleTextField.text, let content = contentTextView.text else { return }
        
        // 從 UserDefaults 中獲取 userId
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("未找到 userId，請先登入")
            return
        }
        
        // 如果有選擇圖片，先上傳圖片並獲取 URL
        if let image = selectedImage {
            uploadImage(image) { [weak self] imageUrl in
                guard let self = self else { return }
                self.imageUrl = imageUrl
                self.savePostData(userId: userId, title: title, content: content, imageUrl: imageUrl)
            }
        } else {
            // 如果沒有圖片，直接儲存發文
            savePostData(userId: userId, title: title, content: content, imageUrl: nil)
        }
    }

    func savePostData(userId: String, title: String, content: String, imageUrl: String?) {
        let posts = Firestore.firestore().collection("posts")
        let document = posts.document()

        let data = [
            "id": document.documentID,
            "userId": userId,
            "title": title,
            "content": content,
            "photoUrl": imageUrl ?? "photo",
            "createdAt": Date(),
            "bookmarkAccount": [String](),
            "likesAccount": [String](),
            "tripId": tripId
        ] as [String : Any]

        document.setData(data)
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
            print("Bookmarked Trip IDs: \(tripIds)")

            if !tripIds.isEmpty {
                FirebaseManager.shared.loadBookmarkedTrips(tripIds: tripIds) { filteredTrips in
                    self.tripsArray = filteredTrips
                    print("Filtered Trips: \(self.tripsArray)")
                    self.dropdownTableView.reloadData()
                }
            } else {
                print("No trips found in bookmarks.")
                self.dropdownTableView.reloadData()
            }
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
        cell.textLabel?.text = tripsArray[indexPath.row].poem.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dropdownButton.setTitle(tripsArray[indexPath.row].poem.title, for: .normal)
        tripId = tripsArray[indexPath.row].id
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
}
