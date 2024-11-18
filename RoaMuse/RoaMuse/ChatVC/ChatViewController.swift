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
import FirebaseStorage

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    let locationManager = LocationManager()
    var tripsArray = [Trip]()
    var chat: Chat?
    let tableView = UITableView()
    let messageTextView = UITextView()
    let sendButton = UIButton(type: .system)
    let photoButton = UIButton(type: .system)
    var chatId: String?
    var chatUserId: String?
    var messages: [ChatMessage] = []
    var currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
    var messageTextViewHeightConstraint: Constraint?
    let sharePhotoButton = UIButton(type: .system)
    let shareTripButton = UIButton(type: .system)
    var stackView = UIStackView()
    var bottomOffsetConstraint: Constraint?
    var isShareOptionsVisible = false
    let popUpView = PopUpView()
    var selectedTrip: Trip?
    var tripTitle = [String: String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.title = chat?.userName
        setupUI()
        popUpView.delegate = self
        if let chatId = chatId {
            loadMessages(chatId: chatId)
        }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = UIColor.deepBlue
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
        tableView.register(TripMessageCell.self, forCellReuseIdentifier: "TripMessageCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .backgroundGray

        view.addSubview(messageTextView)
        messageTextView.delegate = self
        messageTextView.isScrollEnabled = false
        messageTextView.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        messageTextView.textColor = .deepBlue
        messageTextView.layer.cornerRadius = 16
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.borderColor = UIColor.lightGray.cgColor
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)

        view.addSubview(sendButton)
        sendButton.setTitle("發送", for: .normal)
        sendButton.tintColor = .deepBlue
        sendButton.titleLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)

        view.addSubview(photoButton)
        photoButton.tintColor = .deepBlue
        photoButton.setImage(UIImage(systemName: "plus"), for: .normal)
        photoButton.addTarget(self, action: #selector(selectImage), for: .touchUpInside)

        sharePhotoButton.setTitle("分享照片", for: .normal)
        sharePhotoButton.tintColor = .deepBlue
        sharePhotoButton.setImage(UIImage(systemName: "photo"), for: .normal)
        sharePhotoButton.titleLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        sharePhotoButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
        sharePhotoButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        sharePhotoButton.addTarget(self, action: #selector(sharePhoto), for: .touchUpInside)

        shareTripButton.setTitle("分享行程", for: .normal)
        shareTripButton.tintColor = .deepBlue
        shareTripButton.titleLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 16)

        shareTripButton.addTarget(self, action: #selector(shareTrip), for: .touchUpInside)

        stackView = UIStackView(arrangedSubviews: [sharePhotoButton, shareTripButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.isHidden = true
        view.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-15)
            make.height.equalTo(54)
        }

        photoButton.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(16)
            make.centerY.equalTo(messageTextView)
            make.width.height.equalTo(30)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(messageTextView.snp.top).offset(-10)
        }

        messageTextView.snp.makeConstraints { make in
            make.leading.equalTo(photoButton.snp.trailing).offset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.right.equalTo(sendButton.snp.left).offset(-10)
            bottomOffsetConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10).constraint
            messageTextViewHeightConstraint = make.height.equalTo(44).constraint
        }

        sendButton.snp.makeConstraints { make in
            make.right.equalTo(view).offset(-16)
            make.centerY.equalTo(messageTextView)
            make.width.equalTo(40)
        }
    }
    
    @objc func sharePhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    //MARK: work here
    @objc func shareTrip() {
        let sharingTripVC = SharingTripViewController()
        
        sharingTripVC.onTripSelected = { [weak self] selectedTrip in
            guard let self = self else { return }
            self.sendTrip(trip: selectedTrip) 
            self.dismiss(animated: true, completion: nil) 
        }
        
        let navController = UINavigationController(rootViewController: sharingTripVC)
        present(navController, animated: true, completion: nil)
    }
    
    func sendTrip(trip: Trip) {
        guard let chatId = chatId else { return }
        
        let messageRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").document()
        let messageId = messageRef.documentID
        
        let messageData: [String: Any] = [
            "id": messageId,
            "senderId": currentUserId,
            "tripId": trip.id,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ]
        
        messageRef.setData(messageData) { error in
            if let error = error {
                print("發送trip消息失敗: \(error.localizedDescription)")
            } else {
                print("trip消息發送成功")
                Firestore.firestore().collection("chats").document(chatId).updateData([
                    "lastMessage": "傳送了一則行程",
                    "lastMessageTime": FieldValue.serverTimestamp()
                ])
            }
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
                print("加載消息失敗: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.messages = documents.compactMap { document in
                let data = document.data()
                let text = data["text"] as? String ?? ""
                let imageUrl = data["imageUrl"] as? String ?? nil
                let senderId = data["senderId"] as? String ?? ""
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let tripId = data["tripId"] as? String ?? ""
                let messageId = document.documentID
                
                if !tripId.isEmpty {
                    FirebaseManager.shared.loadTripById(tripId) { trip in
                        guard let trip = trip else { return }
                        FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                            self.tripTitle[tripId] = poem.title
                            self.tableView.reloadData()
                        }
                    }
                }
                
                return ChatMessage(id: messageId, text: text, imageUrl: imageUrl, isFromCurrentUser: senderId == self.currentUserId, timestamp: timestamp, tripId: tripId)
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
                self.messageTextView.text = ""
                self.textViewDidChange(self.messageTextView)
                
                Firestore.firestore().collection("chats").document(chatId).updateData([
                    "lastMessage": text,
                    "lastMessageTime": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    @objc func selectImage() {
        isShareOptionsVisible.toggle()

        if isShareOptionsVisible {
            bottomOffsetConstraint?.update(offset: -90)
            stackView.isHidden = false
            photoButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        } else {
            bottomOffsetConstraint?.update(offset: -10)
            stackView.isHidden = true
            photoButton.setImage(UIImage(systemName: "plus"), for: .normal)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let message = messages[indexPath.row]
            
            if let tripId = message.tripId, tripId != "" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TripMessageCell", for: indexPath) as? TripMessageCell
                
                cell?.configure(isFromCurrentUser: message.isFromCurrentUser)
                        
                        if let poemTitle = tripTitle[tripId] {
                            cell?.titleLabel.text = poemTitle
                        } else {
                            cell?.titleLabel.text = "載入中..."
                        }
                
                cell?.moreInfoButton.tag = indexPath.row
                cell?.moreInfoButton.addTarget(self, action: #selector(didTapMoreInfoButton), for: .touchUpInside)
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
                        cell?.avatarImageView.addGestureRecognizer(tapGesture)
                        cell?.avatarImageView.isUserInteractionEnabled = true
                
                return cell ?? UITableViewCell()
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as? ChatMessageCell
                cell?.configure(with: message, profileImageUrl: chat?.profileImage ?? "")
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
                        cell?.avatarImageView.addGestureRecognizer(tapGesture)
                        cell?.avatarImageView.isUserInteractionEnabled = true
                return cell ?? UITableViewCell()
            }
        }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            uploadImage(selectedImage) { [weak self] imageUrl in
                guard let self = self, let chatId = self.chatId else { return }
                
                let messageRef = Firestore.firestore().collection("chats").document(chatId).collection("messages").document()
                let messageId = messageRef.documentID
                
                let messageData: [String: Any] = [
                    "id": messageId,
                    "senderId": self.currentUserId,
                    "imageUrl": imageUrl,
                    "timestamp": FieldValue.serverTimestamp(),
                    "isRead": false
                ]
                
                messageRef.setData(messageData) { error in
                    if let error = error {
                        print("發送圖片消息失敗: \(error.localizedDescription)")
                    } else {
                        print("圖片消息發送成功")
                        Firestore.firestore().collection("chats").document(chatId).updateData([
                            "lastMessage": "傳送了一張圖片",
                            "lastMessageTime": FieldValue.serverTimestamp()
                        ])
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("chat_images/\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(nil)
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                print("圖片上傳失敗: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    print("獲取圖片 URL 失敗: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }
    
    @objc func didTapMoreInfoButton(_ sender: UIButton) {
        let index = sender.tag
        let message = messages[index]
        
        if let tripId = message.tripId, !tripId.isEmpty {
            FirebaseManager.shared.loadTripById(tripId) { [weak self] trip in
                guard let self = self, let trip = trip else { return }
                self.selectedTrip = trip
                self.popUpView.showPopup(on: self.view, with: trip, city: nil, districts: nil)
            }
        }
    }
    
    @objc func avatarTapped(_ sender: UITapGestureRecognizer) {
        print("tap")
        guard let chatId = chatId else { return }
        FirebaseManager.shared.fetchChatParticipant(from: chatId) { userId in
            if let userId = userId {
                print(userId)
                self.navigateToUserProfile(userId: userId)
            }
        }
    }
    
    func navigateToUserProfile(userId: String) {
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = userId
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
}

extension ChatViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        
        guard let selectedTrip = self.selectedTrip else {
            print("Error: Trip is nil!")
            return
        }
        
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = selectedTrip
        self.navigationController?.pushViewController(tripDetailVC, animated: true)
        
    }
}
