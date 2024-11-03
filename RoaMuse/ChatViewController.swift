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

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    var chat: Chat?
    let tableView = UITableView()
    let messageTextView = UITextView()
    let sendButton = UIButton(type: .system)
    var chatId: String?
    var chatUserId: String?
    var messages: [ChatMessage] = []
    var currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
    var messageTextViewHeightConstraint: Constraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.title = chat?.userName
        setupUI()
        
        if let chatId = chatId {
            loadMessages(chatId: chatId)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .backgroundGray
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.deepBlue,
            .font: UIFont(name: "NotoSerifHK-Black", size: 18)
        ]
        
        self.navigationItem.standardAppearance = navBarAppearance
        self.navigationItem.scrollEdgeAppearance = navBarAppearance
        tabBarController?.tabBar.isHidden = true
    }
    
    func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .backgroundGray
        
        view.addSubview(messageTextView)
        messageTextView.delegate = self
        messageTextView.isScrollEnabled = false
        messageTextView.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        messageTextView.layer.cornerRadius = 8
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.lightGray.cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        
        view.addSubview(sendButton)
        sendButton.setTitle("發送", for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(messageTextView.snp.top).offset(-10)
        }
        
        messageTextView.snp.makeConstraints { make in
            make.left.equalTo(view).offset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.right.equalTo(sendButton.snp.left).offset(-10)
            messageTextViewHeightConstraint = make.height.equalTo(44).constraint // 初始高度
        }
        
        sendButton.snp.makeConstraints { make in
            make.right.equalTo(view).offset(-16)
            make.centerY.equalTo(messageTextView)
            make.width.equalTo(60)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let contentHeight = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        let newHeight = min(max(contentHeight, 44), 120)
        
        messageTextViewHeightConstraint?.update(offset: newHeight)
        textView.isScrollEnabled = contentHeight > 120 
        view.layoutIfNeeded()
    }

    func loadMessages(chatId: String) {
        let messageRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").order(by: "timestamp")
        
        messageRef.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("加載消息失败: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.messages = documents.compactMap { document in
                let data = document.data()
                let text = data["text"] as? String ?? ""
                let senderId = data["senderId"] as? String ?? ""
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let messageId = document.documentID
                
                return ChatMessage(id: messageId, text: text, isFromCurrentUser: senderId == self.currentUserId, timestamp: timestamp)
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
        guard let text = messageTextView.text, !text.isEmpty, let chatId = chatId else { return }
        
        let messageRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").document()
        let messageId = messageRef.documentID
        
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": currentUserId,
            "text": text,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ]
        
        messageRef.setData(messageData) { error in
            if let error = error {
                print("發送消息失敗: \(error.localizedDescription)")
            } else {
                print("消息發送成功")
                self.messageTextView.text = "" // 清空輸入框
                self.textViewDidChange(self.messageTextView) // 重置高度
                
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
        cell?.configure(with: message, profileImageUrl: chat?.profileImage ?? "")
        
        return cell ?? UITableViewCell()
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
