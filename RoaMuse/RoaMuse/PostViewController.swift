//
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
    var dropdownOptions = ["Option 1", "Option 2", "Option 3", "Option 4"] // 下拉選單的選項
    var tripsArray = [Trip]()
    var tripId = String()
    
    var postButtonAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDropdownTableView()
        loadTripsData(userId: "Am5Jsa1tA0IpyXMLuilm")
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
    }
    
    //    儲存發文
    @objc func saveData() {
        
        guard let title = titleTextField.text, let content = contentTextView.text else { return }
        
        let posts = Firestore.firestore().collection("posts")
        let document = posts.document()
        
        let data = [
            "id": document.documentID,
            "userId": "yen",
            "title": title,
            "content": content,
            "photoUrl": "photo",
            "createdAt": Date(),
            "bookmarkCount": 5,
            "tripId": tripId
        ] as [String : Any]
        
        document.setData(data)
    }
    
    @objc func backToLastPage() {
        
        postButtonAction?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func toggleDropdown() {
        isDropdownVisible.toggle() // 切換下拉選單的狀態
        
        if isDropdownVisible {
            dropdownTableView.isHidden = false
            dropdownHeightConstraint?.update(offset: CGFloat(dropdownOptions.count * 44))
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
        
        isDropdownVisible = false
        dropdownHeightConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
