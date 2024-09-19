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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        postsTableView.register(PostsTableViewCell.self, forCellReuseIdentifier: "postCell")
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
                print("錯錯錯")
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
        postsTableView.backgroundColor = .blue
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = postsTableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostsTableViewCell
        let postData = postsArray[indexPath.row]
        
        guard let cell = cell else { return UITableViewCell() }
        cell.selectionStyle = .none
        
        cell.titleLabel.text = postsArray[indexPath.row]["title"] as? String
        
        FirebaseManager.shared.isContentBookmarked(forUserId: "Am5Jsa1tA0IpyXMLuilm", id: postsArray[indexPath.row]["id"] as? String ?? "") { isBookmarked in
            cell.collectButton.isSelected = isBookmarked
        }
        
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        // 獲取按鈕點擊所在的行
        let point = sender.convert(CGPoint.zero, to: postsTableView)
        
        if let indexPath = postsTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            let userId = "Am5Jsa1tA0IpyXMLuilm" // 假設為當前使用者ID

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
                                print("取消收藏成功，當前收藏使用者數：\(bookmarkAccount.count)")
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
                                print("收藏成功，當前收藏使用者數：\(bookmarkAccount.count)")
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
