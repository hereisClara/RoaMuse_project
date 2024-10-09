//
//  BlockedListViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import UIKit
import FirebaseFirestore
import SnapKit

class BlockedListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    var blockedUsers: [String] = [] // 封鎖用戶的ID列表
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "封鎖名單"
        
        setupTableView()
        loadBlockedUsers()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "blockedCell")
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // 從 Firebase 加載封鎖的用戶
    func loadBlockedUsers() {
        guard let userId = userId else { return }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("加載封鎖名單失敗: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists, let data = document.data(),
               let blockedUsers = data["blockedUsers"] as? [String] {
                self.blockedUsers = blockedUsers
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedCell", for: indexPath)
        let blockedUserId = blockedUsers[indexPath.row]
        
        // 從 Firebase 獲取被封鎖用戶的名稱
        let userRef = Firestore.firestore().collection("users").document(blockedUserId)
        userRef.getDocument { document, error in
            if let error = error {
                print("獲取用戶失敗: \(error.localizedDescription)")
            } else if let document = document, let data = document.data(), let userName = data["userName"] as? String {
                cell.textLabel?.text = userName
            } else {
                cell.textLabel?.text = "未知用戶"
            }
        }
        
        // 確保每次都移除舊的按鈕，避免重複顯示
        for subview in cell.contentView.subviews {
            if subview is UIButton {
                subview.removeFromSuperview()
            }
        }
        
        // 增加解除封鎖按鈕
        let unblockButton = UIButton(type: .system)
        unblockButton.setTitle("解除封鎖", for: .normal)
        unblockButton.setTitleColor(.systemRed, for: .normal)
        unblockButton.addTarget(self, action: #selector(unblockUser), for: .touchUpInside)
        unblockButton.tag = indexPath.row
        cell.contentView.addSubview(unblockButton)
        
        // 使用 SnapKit 設置按鈕的約束
        unblockButton.snp.makeConstraints { make in
            make.centerY.equalTo(cell.contentView)
            make.trailing.equalTo(cell.contentView).offset(-16)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        return cell
    }

    
    @objc func unblockUser(_ sender: UIButton) {
        let blockedUserId = blockedUsers[sender.tag]
        
        // 彈出一個確認對話框
        let alert = UIAlertController(title: "解除封鎖", message: "你確定要解除這個用戶的封鎖嗎？", preferredStyle: .alert)
        
        // 添加取消動作
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // 添加確定解除封鎖動作
        let confirmAction = UIAlertAction(title: "確定", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.confirmUnblockUser(userId: blockedUserId, index: sender.tag)
        }
        alert.addAction(confirmAction)
        
        // 顯示 alert
        present(alert, animated: true, completion: nil)
    }

    func confirmUnblockUser(userId: String, index: Int) {
        guard let currentUserId = self.userId else { return }
        
        let userRef = Firestore.firestore().collection("users").document(currentUserId)
        userRef.updateData([
            "blockedUsers": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                print("解除封鎖失敗: \(error.localizedDescription)")
            } else {
                print("用戶已解除封鎖")
                self.blockedUsers.remove(at: index)
                self.tableView.reloadData()
            }
        }
    }
}
