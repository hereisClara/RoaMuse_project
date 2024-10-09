//
//  ChatViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var chat: Chat?
    let tableView = UITableView()
    let messageTextField = UITextField()
    let sendButton = UIButton(type: .system)
    
    var chatId: String? // 当前的聊天会话ID
    var chatUserId: String? // 聊天的用户ID
    var messages: [ChatMessage] = []
    var currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.title = chat?.userName
        setupUI()
        
        if let chatId = chatId {
            loadMessages(chatId: chatId)
        }
    }
    
    // 配置界面佈局
    func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        view.addSubview(messageTextField)
        messageTextField.placeholder = "輸入訊息..."
        messageTextField.borderStyle = .roundedRect
        
        view.addSubview(sendButton)
        sendButton.setTitle("發送", for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        // 使用 SnapKit 配置佈局
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(messageTextField.snp.top).offset(-10)
        }
        
        messageTextField.snp.makeConstraints { make in
            make.left.equalTo(view).offset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.height.equalTo(44)
        }
        
        sendButton.snp.makeConstraints { make in
            make.left.equalTo(messageTextField.snp.right).offset(10)
            make.right.equalTo(view).offset(-16)
            make.centerY.equalTo(messageTextField)
            make.width.equalTo(60)
        }
    }
    
    func loadMessages(chatId: String) {
            let messageRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").order(by: "timestamp")
            
            messageRef.addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("加载消息失败: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.messages = documents.compactMap { document in
                    let data = document.data()
                    let text = data["text"] as? String ?? ""
                    let senderId = data["senderId"] as? String ?? ""
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return ChatMessage(text: text, isFromCurrentUser: senderId == self.currentUserId, timestamp: timestamp)
                }
                
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }
    
    func scrollToBottom() {
            if messages.count > 0 {
                let indexPath = IndexPath(row: messages.count - 1, section: 0)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    
    @objc func sendMessage() {
            guard let text = messageTextField.text, !text.isEmpty, let chatId = chatId else { return }
            
            let messageRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").document()
            let messageData: [String: Any] = [
                "senderId": currentUserId,
                "text": text,
                "timestamp": FieldValue.serverTimestamp(),
                "isRead": false
            ]
            
            messageRef.setData(messageData) { error in
                if let error = error {
                    print("发送消息失败: \(error.localizedDescription)")
                } else {
                    print("消息发送成功")
                    self.messageTextField.text = "" // 清空输入框
                    
                    // 更新最后一条消息
                    Firestore.firestore().collection("chats").document(chatId).updateData([
                        "lastMessage": text,
                        "lastMessageTime": FieldValue.serverTimestamp()
                    ])
                }
            }
        }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as? ChatMessageCell
        let message = messages[indexPath.row]
        cell?.configure(with: message)
        return cell ?? UITableViewCell()
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
