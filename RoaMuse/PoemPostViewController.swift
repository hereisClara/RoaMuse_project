//
//  PoemPostViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/9.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class PoemPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var bottomSheetManager: BottomSheetManager?
    var allTripIds = [String]()
    var selectedPoem: Poem?
    var filteredPosts = [[String: Any]]()
    var cityGroupedPoems = [String: [[String: Any]]]() // 用來存儲分組後的貼文數據
    var tableView: UITableView!
    var emptyStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.navigationItem.largeTitleDisplayMode = .never
        setupEmptyStateLabel()
        setupTableView()
        
        getCityToTrip()
        
        bottomSheetManager = BottomSheetManager(parentViewController: self, sheetHeight: 200)
        
        
        bottomSheetManager?.addActionButton(title: "檢舉貼文", textColor: .black) {
            self.presentImpeachAlert()
        }
        bottomSheetManager?.addActionButton(title: "取消", textColor: .red) {
            self.bottomSheetManager?.dismissBottomSheet()
        }
        bottomSheetManager?.setupBottomSheet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
    }
    
    func setupEmptyStateLabel() {
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "現在還沒有這首詩的日記"
        emptyStateLabel.textColor = .lightGray
        emptyStateLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true // 預設為隱藏
        view.addSubview(emptyStateLabel)
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalTo(view) // 在螢幕正中間顯示
        }
    }
    
    func updateEmptyState() {
        print("Filtered Posts Count: \(filteredPosts.count)")
        if filteredPosts.isEmpty {
            print("empty")
            emptyStateLabel.isHidden = false // 顯示提示
            tableView.isHidden = true        // 隱藏 tableView
        } else {
            print("not empty")
            emptyStateLabel.isHidden = true  // 隱藏提示
            tableView.isHidden = false       // 顯示 tableView
        }
    }
    // MARK: - TableView 設置
    
    func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserTableViewCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 240
        tableView.layer.cornerRadius = 20
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.width.equalTo(view).multipliedBy(0.9)
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cityGroupedPoems.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPosts.count // 返回 filteredPosts 的数量
        //        let city = Array(cityGroupedPoems.keys)[section] // 取得對應的城市
        //                return cityGroupedPoems[city]?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as? UserTableViewCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .backgroundGray
        cell.selectionStyle = .none
        
        if filteredPosts.isEmpty {
            print("filteredPosts is empty")
        } else {
            let post = filteredPosts[indexPath.row]
            print("------ ", post)
            cell.configure(with: post)
        }
        
        cell.configureMoreButton {
            self.bottomSheetManager?.showBottomSheet()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = filteredPosts[indexPath.row]
        
        let articleVC = ArticleViewController()
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
                articleVC.tripId = post["tripId"] as? String ?? ""
                articleVC.photoUrls = post["photoUrls"] as? [String] ?? []
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
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(cityGroupedPoems.keys)[section] // 返回每個 section 的城市名稱作為標題
    }
    
    // MARK: - 加載數據
    
    func loadFilteredPosts(allTripIds: [String], completion: @escaping ([[String: Any]]) -> Void) {
        
        guard !allTripIds.isEmpty else {
            completion([])
            return
        }
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("无法获取当前用户 ID")
            completion([])
            return
        }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        currentUserRef.getDocument { snapshot, error in
            if let error = error {
                print("无法加载封锁状态: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let blockedUsers = snapshot?.data()?["blockedUsers"] as? [String] ?? []
            
            let dispatchGroup = DispatchGroup()
            var allFilteredPosts = [[String: Any]]()
            
            for tripId in allTripIds {
                print("Querying posts for tripId: \(tripId)") // 印出正在查询的 tripId
                dispatchGroup.enter()
                Firestore.firestore().collection("posts")
                    .whereField("tripId", isEqualTo: tripId)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error loading posts for tripId \(tripId): \(error.localizedDescription)")
                            dispatchGroup.leave()
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            print("No posts found for tripId \(tripId)")
                            dispatchGroup.leave()
                            return
                        }
                        
                        let filteredPosts = documents.compactMap { document -> [String: Any]? in
                            let postData = document.data()
                            let postUserId = postData["userId"] as? String ?? ""
                            
                            if blockedUsers.contains(postUserId) {
                                print("Post from blocked user \(postUserId) ignored")
                                return nil
                            }
                            print("Post found: \(postData)") // 印出找到的资料
                            return postData
                        }
                        
                        allFilteredPosts.append(contentsOf: filteredPosts)
                        dispatchGroup.leave()
                    }
            }
            
            // 当所有异步查询完成后，通知回调并返回所有的 post
            dispatchGroup.notify(queue: .main) {
                print("All filtered posts fetched: \(allFilteredPosts)") // 打印所有返回的 filtered posts
                completion(allFilteredPosts) // 返回所有过滤后的帖子
            }
        }
    }
    
    func presentImpeachAlert() {
            let alertController = UIAlertController(title: "檢舉貼文", message: "你確定要檢舉這篇貼文嗎？", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "確定", style: .destructive) { _ in
                self.bottomSheetManager?.dismissBottomSheet()
            }
            alertController.addAction(confirmAction)
            
            present(alertController, animated: true, completion: nil)
        }
    
    func getCityToTrip() {
        if let selectedPoem = selectedPoem {
            FirebaseManager.shared.getCityToTrip(poemId: selectedPoem.id) { poemsArray, error in
                if let error = error {
                    print("Error retrieving data: \(error.localizedDescription)")
                    return
                } else if let poemsArray = poemsArray {
                    print("in else if")
                    for poem in poemsArray {
                        if let city = poem["city"] as? String {
                            print("city isn't empty")
                            if var existingPoems = self.cityGroupedPoems[city] {
                                existingPoems.append(poem)
                                self.cityGroupedPoems[city] = existingPoems
                            } else {
                                self.cityGroupedPoems[city] = [poem]
                            }
                        }
                        
                        if let tripId = poem["tripId"] as? String {
                            print("tripId: \(tripId)")
                            self.allTripIds.append(tripId)
                        }
                    }
                    print("All Trip Ids: \(self.allTripIds)")
                    
                    // Load filtered posts and update table view
                    self.loadFilteredPosts(allTripIds: self.allTripIds) { filteredPosts in
                        self.filteredPosts = filteredPosts
                        
                        print("Filtered Posts: \(self.filteredPosts)")
                        self.updateEmptyState()
                        self.tableView.reloadData() // 在获取数据后重新载入表格
                    }
                }
            }
        }
    }
    
    
    //    func groupFilteredPostsByCity(filteredPosts: [[String: Any]]) {
    //        // 創建一個臨時字典來保存分組貼文
    //        var groupedPosts = [String: [[String: Any]]]()
    //
    //        for post in filteredPosts {
    //            // 獲取貼文的 tripId
    //            if let tripId = post["tripId"] as? String {
    //                // 遍歷 cityGroupedPoems 找到對應的城市
    //                for (city, poems) in cityGroupedPoems {
    //                    if poems.contains(where: { $0["tripId"] as? String == tripId }) {
    //                        if var cityPosts = groupedPosts[city] {
    //                            cityPosts.append(post)
    //                            groupedPosts[city] = cityPosts
    //                        } else {
    //                            groupedPosts[city] = [post]
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //
    //        // 更新 cityGroupedPoems 為過濾後的分組貼文
    //        self.cityGroupedPoems = groupedPosts
    //    }
}
