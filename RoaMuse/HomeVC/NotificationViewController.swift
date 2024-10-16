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
        
        self.title = "通知"
        self.navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .backgroundGray
        
        // 创建自定义的导航栏外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground() // 根据需要设置透明或不透明背景
        navBarAppearance.backgroundColor = .white  // 设置背景颜色
        
        // 设置导航栏标题的自定义字体和颜色
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 18) {
            navBarAppearance.titleTextAttributes = [
                .font: customFont,
                .foregroundColor: UIColor.deepBlue // 自定义颜色
            ]
        }
        
        navigationController?.navigationBar.tintColor = .deepBlue
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        setupTableView()
        fetchNotifications()

        let clearButton = UIBarButtonItem(title: "清除", style: .plain, target: self, action: #selector(clearAllNotifications))
        
        let buttonAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "NotoSerifHK-Black", size: 16)!,  // 替换成你想要的字体和大小
            .foregroundColor: UIColor.forBronze  // 自定义颜色
        ]
        clearButton.setTitleTextAttributes(buttonAttributes, for: .normal)
        
        navigationItem.rightBarButtonItem = clearButton
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
        
        FirebaseManager.shared.fetchNotifications(forUserId: userId) { [weak self] notifications in
            
            self?.notifications = notifications.sorted { $0.createdAt > $1.createdAt }
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
    
    @objc func clearAllNotifications() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found in UserDefaults")
            return
        }

        let db = Firestore.firestore()
        let notificationCollection = db.collection("notifications").whereField("to", isEqualTo: userId)

        notificationCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching notifications: \(error.localizedDescription)")
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No notifications to delete")
                return
            }

            let batch = db.batch()

            for document in documents {
                let documentRef = db.collection("notifications").document(document.documentID)
                batch.deleteDocument(documentRef)
            }

            batch.commit { error in
                if let error = error {
                    print("Error deleting notifications: \(error.localizedDescription)")
                } else {
                    print("All notifications cleared successfully")
                    
                    self.notifications.removeAll()
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
}
