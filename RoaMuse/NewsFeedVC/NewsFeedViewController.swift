//
//  NewsFeedViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import MJRefresh

class NewsFeedViewController: UIViewController {
    
    let postViewController = PostViewController()
    let db = Firestore.firestore()
    var postsArray = [[String: Any]]()
    let postsTableView = UITableView()
    let postButton = UIButton(type: .system)
    
    var likeCount = String()
    var bookmarkCount = String()
    var likeButtonIsSelected = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postsTableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        postsTableView.delegate = self
        postsTableView.dataSource = self
        view.backgroundColor = UIColor(resource: .backgroundGray)
        setupPostButton()
        setupPostsTableView()
        setupRefreshControl()
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.postsTableView.reloadData()
        }
        
        postViewController.postButtonAction = { [weak self] in
            
            guard let self = self else { return }
            
            FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
                self.postsArray.insert(contentsOf: newPosts, at: 0)
                self.postsTableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 每次回到這個頁面時重新加載資料
        FirebaseManager.shared.loadPosts { [weak self] postsArray in
            self?.postsArray = postsArray
            DispatchQueue.main.async {
                self?.postsTableView.reloadData() // 確保 UI 更新
            }
        }
    }
    
    func setupPostButton() {
        
        view.addSubview(postButton)
        
        postButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
        }
        
        postButton.setTitle("發文", for: .normal)
        postButton.backgroundColor = .lightGray
        postButton.addTarget(self, action: #selector(didTapPostButton), for: .touchUpInside)
    }
    
    @objc func didTapPostButton() {
        
        navigationController?.pushViewController(postViewController, animated: true)
        
    }
    
    func getNewData() {
        
        var postsIdArray = [String]()
        
        db.collection("posts").getDocuments { querySnapshot, error in
            if error != nil {
//                print("錯錯錯")
            } else {
                
                for num in 0 ..< self.postsArray.count {
                    
                    let postId = self.postsArray[num]["id"] as? String
                    postsIdArray.append(postId ?? "")
                }
                
                for document in querySnapshot!.documents {
                    if !postsIdArray.contains(document.data()["id"] as? String ?? "") {
                        self.postsArray.insert(document.data(), at: 0)
                    }
                }
                
                self.postsTableView.reloadData()
                self.postsTableView.mj_header?.endRefreshing()
            }
        }
    }
    
    func setupRefreshControl() {
        // 使用 MJRefreshNormalHeader，當下拉時觸發的刷新動作
        postsTableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.getNewData() // 在刷新時重新加載數據
        })
    }
    
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        let point = sender.convert(CGPoint.zero, to: postsTableView)
        
        if let indexPath = postsTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            
            guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
            saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
                if success {
                    
                    FirebaseManager.shared.loadPosts { posts in
                        let filteredPosts = posts.filter { post in
                            return post["id"] as? String == postId
                        }
                        if let matchedPost = filteredPosts.first,
                           let likesAccount = matchedPost["likesAccount"] as? [String] {
                            // 更新 likeCountLabel
                            self.likeCount = String(likesAccount.count)
                            self.likeButtonIsSelected = likesAccount.contains(userId)
                        } else {
                            // 如果沒有找到相應的貼文，或者 likesAccount 為空
                            self.likeCount = "0"
                            self.likeButtonIsSelected = false
                        }
                    }
                    
                } else {
                    sender.isSelected.toggle()
                }
            }
        }
    }
    
    func saveLikeData(postId: String, userId: String, isLiked: Bool, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        if isLiked {
            // 使用 arrayUnion 將 userId 添加到 likesAccount 列表中
            postRef.updateData([
                "likesAccount": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    print("按讚失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    //                    print("按讚成功，已更新資料")
                    completion(true)
                }
            }
        } else {
            // 使用 arrayRemove 將 userId 從 likesAccount 列表中移除
            postRef.updateData([
                "likesAccount": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    print("取消按讚失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    //                    print("取消按讚成功，已更新資料")
                    completion(true)
                }
            }
        }
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        // 獲取按鈕點擊所在的行
        let point = sender.convert(CGPoint.zero, to: postsTableView)
        
        if let indexPath = postsTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

            
            // 獲取當前的 bookmarkAccount
            var bookmarkAccount = postData["bookmarkAccount"] as? [String] ?? []
            
            if sender.isSelected {
                // 如果按鈕已選中，取消收藏並移除 userId
                bookmarkAccount.removeAll { $0 == userId }
                
                FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                    if success {
                        // 更新 Firestore 中的 bookmarkAccount 字段
                        self.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                            if let error = error {
                                print("Failed to update bookmarkAccount: \(error)")
                            } else {
                                //                                print("取消收藏成功，當前收藏使用者數：\(bookmarkAccount.count)")
                            }
                        }
                    } else {
                        print("取消收藏失敗")
                    }
                }
            } else {
                // 如果按鈕未選中，進行收藏並加入 userId
                if !bookmarkAccount.contains(userId) {
                    bookmarkAccount.append(userId)
                }
                
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        // 更新 Firestore 中的 bookmarkAccount 字段
                        self.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                            if let error = error {
                                print("Failed to update bookmarkAccount: \(error)")
                            } else {
                                //                                print("收藏成功，當前收藏使用者數：\(bookmarkAccount.count)")
                            }
                        }
                    } else {
                        print("收藏失敗")
                    }
                }
            }
            // 更新按鈕選中狀態
            sender.isSelected.toggle()
        }
    }
}

extension NewsFeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func setupPostsTableView() {
        
        view.addSubview(postsTableView)
        
        postsTableView.snp.makeConstraints { make in
            make.top.equalTo(postButton.snp.bottom).offset(40)
            make.width.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        postsTableView.allowsSelection = true
//        postsTableView.backgroundColor = .blue
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = postsTableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell
        let postData = postsArray[indexPath.row]
        
        guard let cell = cell else { return UITableViewCell() }
        
        // 獲取貼文發佈者的 userId
        guard let postOwnerId = postData["userId"] as? String else { return UITableViewCell() }
        
        cell.selectionStyle = .none
        cell.titleLabel.text = postData["title"] as? String
        cell.contentLabel.text = postData["content"] as? String
        cell.likeButton.addTarget(self, action: #selector(self.didTapLikeButton(_:)), for: .touchUpInside)
        cell.likeButton.isSelected = self.likeButtonIsSelected
        cell.likeCountLabel.text = self.likeCount
        
        if let createdAtTimestamp = postData["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            cell.dateLabel.text = createdAtString
        }
        
        // 檢查該貼文是否已被當前用戶收藏
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return cell }
        
        FirebaseManager.shared.isContentBookmarked(forUserId: currentUserId, id: postData["id"] as? String ?? "") { isBookmarked in
            DispatchQueue.main.async {
                cell.collectButton.isSelected = isBookmarked
            }
        }
        
        // 獲取貼文發佈者的資料（頭像）
        FirebaseManager.shared.fetchUserData(userId: postOwnerId) { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    // 使用 Kingfisher 加載圖片到 avatarImageView
                    DispatchQueue.main.async {
                        cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                }
            case .failure(let error):
                print("加載貼文發佈者的頭像失敗: \(error.localizedDescription)")
            }
        }
        
        // 加載貼文的按讚數據
        FirebaseManager.shared.loadPosts { posts in
            let filteredPosts = posts.filter { post in
                return post["id"] as? String == postData["id"] as? String
            }
            if let matchedPost = filteredPosts.first,
               let likesAccount = matchedPost["likesAccount"] as? [String] {
                // 更新 likeCountLabel 和按鈕的選中狀態
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = String(likesAccount.count)
                    cell.likeButton.isSelected = likesAccount.contains(currentUserId) // 依據是否按讚來設置狀態
                }
            } else {
                DispatchQueue.main.async {
                    cell.likeCountLabel.text = "0"
                    cell.likeButton.isSelected = false // 如果沒有按讚，設置為未選中
                }
            }
        }
        
        cell.collectButton.addTarget(self, action: #selector(self.didTapCollectButton(_:)), for: .touchUpInside)
        
        return cell
    }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let post = postsArray[indexPath.row]
            
            let articleVC = ArticleViewController()
            
            // 傳遞貼文的資料
            
            FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
                if let userName = userName {
                    articleVC.articleAuthor = userName
                    articleVC.articleTitle = post["title"] as? String ?? "無標題"
                    articleVC.articleContent = post["content"] as? String ?? "無內容"
                    articleVC.tripId = post["tripId"] as? String ?? ""
                    if let createdAtTimestamp = post["createdAt"] as? Timestamp {
                        let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                        articleVC.articleDate = createdAtString
                    }
                    
                    articleVC.authorId = post["userId"] as? String ?? ""
                    articleVC.postId = post["id"] as? String ?? ""
                    articleVC.bookmarkAccounts = post["bookmarkAccount"] as? [String] ?? []
                    
                    self.navigationController?.pushViewController(articleVC, animated: true)
                } else {
                    print("未找到對應的 userName")
                }
            }
        }
    }

