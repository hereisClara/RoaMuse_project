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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        setupUI()
        setupDropdownTableView()
        
        // 從 UserDefaults 中讀取 userId
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("未找到 userId，請先登入")
            return
        }
        
        // 加載該 userId 對應的行程數據
        loadTripsData(userId: userId)
    }
    
    func setupUI() {
        view.addSubview(contentTextView)
        view.addSubview(titleTextField)
        view.addSubview(postButton)
        view.addSubview(dropdownButton)
        view.addSubview(imageButton)
        
        contentTextView.text = ""
        titleTextField.text = ""
        
        contentTextView.backgroundColor = .systemGray5
        titleTextField.backgroundColor = .systemGray6
        dropdownButton.setTitle("Select Option", for: .normal)
        dropdownButton.backgroundColor = .orange
        dropdownButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        
        imageButton.setTitle("選擇圖片", for: .normal)
        imageButton.backgroundColor = .systemBlue
        imageButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(50)
            make.width.equalTo(250)
            make.centerX.equalTo(view)
        }
        
        dropdownButton.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(20)
            make.centerX.equalTo(view)
            make.width.equalTo(250)
            make.height.equalTo(50)
        }
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(dropdownButton.snp.bottom).offset(20)
            make.width.height.equalTo(250)
            make.centerX.equalTo(view)
        }
        
        postButton.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(50)
            make.centerX.equalTo(view)
        }
        
        imageButton.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(100)  // 確認是與 contentTextView 的底部對齊
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.8)
            make.height.equalTo(50)
        }

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
            // 儲存選擇的圖片
            selectedImage = image
            
            // 將圖片轉換成 JPEG 格式的 Data
            guard let imageData = image.jpegData(compressionQuality: 0.75) else {
                print("無法壓縮圖片")
                return
            }
            
            // 開始上傳圖片
            uploadImageToFirebase(imageData) { [weak self] imageUrl in
                if let imageUrl = imageUrl {
                    // 獲取圖片的下載 URL 並儲存
                    self?.imageUrl = imageUrl
                    print("圖片上傳成功，下載 URL：\(imageUrl)")
                } else {
                    print("圖片上傳失敗")
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
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
        dropdownTableView.isHidden = true
        dropdownTableView.dataSource = self
        dropdownTableView.delegate = self
        dropdownTableView.register(UITableViewCell.self, forCellReuseIdentifier: "dropdownCell")
        
        view.addSubview(dropdownTableView)
        
        dropdownTableView.snp.makeConstraints { make in
            make.top.equalTo(dropdownButton.snp.bottom).offset(10)
            make.centerX.equalTo(view)
            make.width.equalTo(dropdownButton)
            dropdownHeightConstraint = make.height.equalTo(0).constraint // 初始高度設置為 0
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
        // 檢查是否標題和內容都非空且不僅僅是空格
        let isTitleValid = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let isContentValid = !content.trimmingCharacters(in: .whitespaces).isEmpty
        let isTripSelected = !tripId.isEmpty
        
        // 發文按鈕在三者都滿足條件時才啟用
        postButton.isEnabled = isTitleValid && isContentValid && isTripSelected
    }
}
