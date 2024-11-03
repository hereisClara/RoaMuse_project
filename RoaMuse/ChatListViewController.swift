//
//  ChatListViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let tableView = UITableView()
    var chats: [Chat] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.title = "聊天室"
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = UIColor.deepBlue
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .white
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.deepBlue,
            .font: UIFont(name: "NotoSerifHK-Black", size: 18)
        ]
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatListCell.self, forCellReuseIdentifier: "ChatListCell")
    }
    
    func loadChats() {
        let db = Firestore.firestore()
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        db.collection("chats").whereField("participants", arrayContains: currentUserId).addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("加載聊天數據失敗: \(error)")
                return
            }
            
            self.chats.removeAll()
            
            if let documents = snapshot?.documents {
                for document in documents {
                    let data = document.data()
                    let chatId = document.documentID
                    let lastMessage = data["lastMessage"] as? String ?? ""
                    let participants = data["participants"] as? [String] ?? []
                    let lastMessageTime = (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date()
                    
                    var chat = Chat(id: chatId, userName: "無名", lastMessage: lastMessage, profileImage: "", lastMessageTime: lastMessageTime)
                    
                    if let otherUserId = participants.first(where: { $0 != currentUserId }) {
                        db.collection("users").document(otherUserId).getDocument { (userSnapshot, userError) in
                            if let userError = userError {
                                print("加載用戶資料失敗: \(userError)")
                                return
                            }
                            
                            if let userData = userSnapshot?.data() {
                                let userName = userData["userName"] as? String ?? "無名"
                                let profileImage = userData["photo"] as? String ?? ""
                                
                                chat = Chat(id: chatId, userName: userName, lastMessage: lastMessage, profileImage: profileImage, lastMessageTime: lastMessageTime)
                            }
                            
                            self.chats.append(chat)
                            self.chats.sort { $0.lastMessageTime > $1.lastMessageTime }
                            self.tableView.reloadData()
                        }
                    } else {
                        self.chats.append(chat)
                        self.chats.sort { $0.lastMessageTime > $1.lastMessageTime }
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as? ChatListCell else {
            return UITableViewCell()
        }
        
        let chat = chats[indexPath.row]
        cell.configure(with: chat)
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedChat = chats[indexPath.row]
        
        let chatVC = ChatViewController()
        chatVC.chat = selectedChat
        chatVC.chatId = selectedChat.id
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
