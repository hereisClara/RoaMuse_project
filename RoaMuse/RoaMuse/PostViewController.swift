//  PostViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class PostViewController: UIViewController {
    
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
        
        contentTextView.text = ""
        titleTextField.text = ""
        
        contentTextView.backgroundColor = .systemGray5
        titleTextField.backgroundColor = .systemGray6
        dropdownButton.setTitle("Select Option", for: .normal)
        dropdownButton.backgroundColor = .orange
        dropdownButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        
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
        
        contentTextView.font = UIFont.systemFont(ofSize: 20)
        postButton.setTitle("發文", for: .normal)
        postButton.addTarget(self, action: #selector(saveData), for: .touchUpInside)
        postButton.addTarget(self, action: #selector(backToLastPage), for: .touchUpInside)
        
        postButton.isEnabled = false
        
        titleTextField.delegate = self
        contentTextView.delegate = self
    }
    
    // 儲存發文
    @objc func saveData() {
        guard let title = titleTextField.text, let content = contentTextView.text else { return }
        
        // 從 UserDefaults 中獲取 userId
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("未找到 userId，請先登入")
            return
        }
        
        let posts = Firestore.firestore().collection("posts")
        let document = posts.document()
        
        let data = [
            "id": document.documentID,
            "userId": userId, // 使用從 UserDefaults 取得的 userId
            "title": title,
            "content": content,
            "photoUrl": "photo",
            "createdAt": Date(),
            "bookmarkAccount": [String](),  // 收藏者帳號列表
            "likesAccount": [String](),     // 按讚者帳號列表
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
