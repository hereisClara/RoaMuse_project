//
//  ChatListViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore // 確保你已經導入 Firebase Firestore

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let tableView = UITableView()
    var chats: [Chat] = [] // 存儲聊天數據
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        self.title = "聊天室"
        
        setupTableView()
        
        loadChats() // 加載聊天數據
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
    
    // 從 Firebase 實時加載聊天數據
    func loadChats() {
        let db = Firestore.firestore()
        
        // 假設聊天數據存儲在名為 "chats" 的集合中
        db.collection("chats").addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("加載聊天數據失敗: \(error)")
                return
            }
            
            // 清空原來的聊天數據
            self.chats.removeAll()
            
            // 解析聊天數據
            if let documents = snapshot?.documents {
                for document in documents {
                    let data = document.data()
                    let userName = data["userName"] as? String ?? "無名"
                    let lastMessage = data["lastMessage"] as? String ?? ""
                    let profileImage = data["profileImage"] as? String ?? ""
                    
                    // 創建 Chat 模型
                    let chat = Chat(userName: userName, lastMessage: lastMessage, profileImage: profileImage)
                    self.chats.append(chat)
                }
                
                // 刷新表格視圖
                self.tableView.reloadData()
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
        
        // 獲取選中的聊天
        let selectedChat = chats[indexPath.row]
        
        // 跳轉到相應的聊天室頁面
        let chatVC = ChatViewController()
        chatVC.chat = selectedChat  // 將選中的聊天傳遞到聊天室
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
