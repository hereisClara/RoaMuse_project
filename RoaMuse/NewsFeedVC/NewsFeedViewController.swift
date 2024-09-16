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
        
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.postsTableView.reloadData()
        }

        postViewController.postButtonAction = { [weak self] in
            
            guard let self = self else { return }
            
            FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
                self.postsArray.append(contentsOf: newPosts)
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
    
    func getData() {
        
        db.collection("posts").order(by: "createdAt", descending: true).getDocuments { querySnapshot, error in
            if error != nil {
                print("錯錯錯")
            } else {
                for document in querySnapshot!.documents {
                    self.postsArray.append(document.data())
                }
                print(self.postsArray)
                self.postsTableView.reloadData()
            }
        }
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
            }
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
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        // 將按鈕點擊的位置轉換為 UITableView 中的點
        let point = sender.convert(CGPoint.zero, to: postsTableView)
        
        // 通過這個點查詢對應的 indexPath
        if let indexPath = postsTableView.indexPathForRow(at: point) {
            // 獲取該行的數據
            let postData = postsArray[indexPath.row]
            
            print("點擊了第 \(indexPath.row) 行的愛心按鈕")
            print("該行的資料: \(postData)")
            
            // 在這裡進行進一步處理，比如更新數據源或 UI
            updateUserCollections(userId: "qluFSSg8P1fGmWfXjOx6", postId: postData["id"] as? String ?? "")
        }
    }
    
    func updateUserCollections(userId: String, postId: String) {
        // 獲取 Firestore 的引用
        let db = Firestore.firestore()
        
        // 指定用戶文檔的路徑
        let userRef = db.collection("users").document(userId)
        
        // 使用 `updateData` 方法只更新 followersCount 字段
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // 如果文檔存在，則更新收藏
                userRef.updateData([
                    "bookmarkPost": FieldValue.arrayUnion([postId])
                ]) { error in
                    if let error = error {
                        print("更新收藏失敗：\(error.localizedDescription)")
                    } else {
                        print("收藏更新成功！")
                    }
                }
            } else {
                // 如果文檔不存在，提示錯誤或創建新文檔
                print("文檔不存在，無法更新")
            }
        }
    }
}
