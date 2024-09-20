//
//  UserViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit
import SnapKit
import FirebaseCore

class UserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    let userNameLabel = UILabel()
    let awardsLabel = UILabel()
    var userName = String()
    var awards = Int()
    var posts: [[String: Any]] = []
 
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        setupTableView()
        
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    print(userName)
                    self?.userName = userName
                    self?.userNameLabel.text = userName
                }
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
            
            FirebaseManager.shared.countCompletedPlaces(userId: userId) { totalPlaces in
                print("使用者總共完成了 \(totalPlaces) 個地點")
                self?.awards = totalPlaces
                self?.awardsLabel.text = String(self?.awards ?? 0)
            }
        }
        
        self.loadUserPosts()
    }
    
    // 設置 TableView
    func setupTableView() {
        view.addSubview(tableView)
        
        // 註冊自定義 cell
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")
        
        // 設置代理和資料來源
        tableView.delegate = self
        tableView.dataSource = self
        
        // 設置 Header
        let headerView = UIView()
        headerView.backgroundColor = .lightGray
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)
        
        userNameLabel.text = userName
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(userNameLabel)
        
        awardsLabel.text = "打開卡片：\(String(self.awards))張"
        awardsLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        headerView.addSubview(awardsLabel)
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(headerView).offset(16)
        }
        
        awardsLabel.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
        }
        
        tableView.tableHeaderView = headerView
        
        // 設置 TableView 大小等於 safeArea
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // UITableViewDataSource - 設定 cell 的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    // UITableViewDataSource - 設定每個 cell 的樣式
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell else {
            return UITableViewCell()
        }
        
        let post = posts[indexPath.row]
        let title = post["title"] as? String ?? "無標題"
        
        // 設置 cell 的文章標題
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        let articleVC = ArticleViewController()
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                print("找到的 userName: \(userName)")
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
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
    
    // UITableViewDelegate - 設定 cell 高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180 // 設定 cell 高度
    }
    
    func loadUserPosts() {
        FirebaseManager.shared.loadSpecifyUserPost(forUserId: userId) { [weak self] postsArray in
            guard let self = self else { return }
            
            // 根據文章的 createdAt 時間戳排序
            self.posts = postsArray.sorted(by: { (post1, post2) -> Bool in
                if let createdAt1 = post1["createdAt"] as? Timestamp,
                   let createdAt2 = post2["createdAt"] as? Timestamp {
                    return createdAt1.dateValue() > createdAt2.dateValue()
                }
                return false
            })
            print("加載到的文章數據: \(self.posts)")
            // 重新載入表格數據
            self.tableView.reloadData()
        }
    }

}
