//
//  NotificationViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/7.
//

import Foundation
import UIKit
import FirebaseFirestore
import Kingfisher

class NotificationViewController: UIViewController {
    
    let tableView = UITableView()
    
    var notifications: [Notification] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "通知"
        self.navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
        
        setupTableView()
        fetchNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // 設置 tableView
    func setupTableView() {
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    func fetchNotifications() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found in UserDefaults")
            return
        }
        
        // 調用 FirebaseManager 的 fetchNotifications 方法，過濾出 to 是當前用戶的通知
        FirebaseManager.shared.fetchNotifications(forUserId: userId) { [weak self] notifications in
            // 在這裡對 notifications 進行排序
            self?.notifications = notifications.sorted { $0.createdAt > $1.createdAt }
            print("-----", self?.notifications)
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension NotificationViewController: UITableViewDataSource, UITableViewDelegate {
    
    // 設置通知的行數
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as? NotificationTableViewCell
        let notification = notifications[indexPath.row]
        
        cell?.avatarImageView.image = UIImage(named: "avatar_placeholder")
        
        fetchUserAvatar(userId: notification.from) { avatarUrl in
            cell?.configure(with: notification, avatarUrl: avatarUrl?.absoluteString)
        }
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let notification = notifications[indexPath.row]
        print("選擇了通知: \(notification.title)")
        
    }
    
    // 從 Firestore 加載用戶的頭像 URL
    func fetchUserAvatar(userId: String, completion: @escaping (URL?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    completion(photoUrl)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}
