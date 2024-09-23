//
//  CollectionsViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit
import SnapKit
import MJRefresh
import FirebaseCore
import FirebaseFirestore

class CollectionsViewController: UIViewController {
    
    let segmentedControl = UISegmentedControl(items: ["行程", "日記"])
    let collectionsTableView = UITableView()
    var bookmarkPostIdArray = [String]()
    var bookmarkTripIdArray = [String]()
    var postsArray = [[String: Any]]()
    var tripsArray = [Trip]() // 更新為存儲從 Firebase 獲取的行程
    var segmentIndex = 0
    
    var incompleteTripsArray = [Trip]()
    var completeTripsArray = [Trip]()
    
    var filterButtons: [UIButton] = []
    var selectedFilterIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        loadInitialData()
        setupUI()
        setupTableView()
        setupSegmentedControl()
        setupRefreshControl()
        setupFilterButtons()
    }
    
    func setupUI() {
        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(100)
            make.width.equalTo(view).multipliedBy(0.8)
            make.height.equalTo(60)
        }
    }
    
    func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
    }
    
    func setupTableView() {
        view.addSubview(collectionsTableView)
        collectionsTableView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(segmentedControl.snp.bottom).offset(20)
            make.width.equalTo(view).multipliedBy(0.8)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
        collectionsTableView.backgroundColor = .cyan
        collectionsTableView.allowsSelection = true
        collectionsTableView.register(CollectionsTableViewCell.self, forCellReuseIdentifier: "collectionsCell")
        collectionsTableView.delegate = self
        collectionsTableView.dataSource = self
    }
    
    @objc func segmentedControlChanged(_ sender: UISegmentedControl) {
        segmentIndex = sender.selectedSegmentIndex
        resetFilterButtons()
        loadInitialData()
    }
    
    func loadInitialData() {
        if segmentIndex == 0 {
            loadTripsData(userId: userId)
            print("/////////////", incompleteTripsArray)
        } else {
            loadPostsData()
        }
    }
    
    // 加載收藏的行程
    func loadTripsData(userId: String) {
        self.tripsArray.removeAll() // 清空之前的數據
        
        // 首先加載使用者的 bookmarkTrip 和 completedTrip
        let userRef = FirebaseManager.shared.db.collection("users").document(userId)
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found.")
                return
            }
            
            // 拿到 bookmarkTrip 和 completedTrip 的數組
            let bookmarkTripIds = data["bookmarkTrip"] as? [String] ?? []
            let completedTripIds = data["completedTrip"] as? [String] ?? []
            
            // 過濾出未完成的 trip Ids
            let incompleteTripIds = bookmarkTripIds.filter { !completedTripIds.contains($0) }
            let completeTripIds = bookmarkTripIds.filter { completedTripIds.contains($0) }
            
            // 使用這些 IDs 從 trips 集合中獲取對應的行程數據
            FirebaseManager.shared.loadBookmarkedTrips(tripIds: incompleteTripIds) { [weak self] incompleteTrips in
                guard let self = self else { return }
                self.incompleteTripsArray = incompleteTrips
                
                FirebaseManager.shared.loadBookmarkedTrips(tripIds: completeTripIds) { [weak self] completeTrips in
                    guard let self = self else { return }
                    self.completeTripsArray = completeTrips
                    
                    // 更新 tableView
                    DispatchQueue.main.async {
                        self.collectionsTableView.reloadData()
                        self.collectionsTableView.mj_header?.endRefreshing()
                    }
                }
            }
        }
    }
    
    
    
    // 加載收藏的文章
    func loadPostsData() {
        self.postsArray.removeAll()
        
        // 使用 FirebaseManager 載入收藏的貼文
        FirebaseManager.shared.loadBookmarkPostIDs(forUserId: "Am5Jsa1tA0IpyXMLuilm") { [weak self] postIds in
            guard let self = self else { return }
            self.bookmarkPostIdArray = postIds
            print("Bookmarked Post IDs: \(postIds)") // Debugging
            
            if !postIds.isEmpty {
                // 加載所有文章並過濾出已收藏的文章
                FirebaseManager.shared.loadPosts { [weak self] posts in
                    guard let self = self else { return }
                    self.postsArray = posts.filter { postIds.contains($0["id"] as? String ?? "") }
                    self.collectionsTableView.reloadData()
                    self.collectionsTableView.mj_header?.endRefreshing()
                }
            } else {
                print("No posts found in bookmarks.") // Debugging
                self.collectionsTableView.reloadData() // 確保即使沒有數據也更新 UI
                self.collectionsTableView.mj_header?.endRefreshing()
            }
        }
    }
    
    func setupRefreshControl() {
        // 使用 MJRefreshNormalHeader，當下拉時觸發的刷新動作
        collectionsTableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let self = self else { return }
            self.loadInitialData() // 在刷新時重新加載數據
        })
    }
    
    //    func setupFilterButtons() {
    //        let filterOptions = ["奇險派", "浪漫派", "田園派"]
    //        
    //        let buttonContainer = UIStackView()
    //        buttonContainer.axis = .horizontal
    //        buttonContainer.distribution = .fillEqually
    //        buttonContainer.spacing = 8
    //        view.addSubview(buttonContainer)
    //        
    //        buttonContainer.snp.makeConstraints { make in
    //            make.bottom.equalTo(segmentedControl.snp.top).offset(-20)
    //            make.width.equalTo(segmentedControl)
    //            make.centerX.equalTo(view)
    //            make.height.equalTo(50)
    //        }
    //        
    //        for (index, title) in filterOptions.enumerated() {
    //            let button = UIButton(type: .system)
    //            button.setTitle(title, for: .normal)
    //            button.tag = index
    //            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
    //            button.backgroundColor = .clear
    //            button.setTitleColor(.deepBlue, for: .normal)
    //            buttonContainer.addArrangedSubview(button)
    //            filterButtons.append(button)
    //        }
    //    }
    
    func setupFilterButtons() {
        let filterOptions = ["奇險派", "浪漫派", "田園派"]
        
        let buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 8
        view.addSubview(buttonContainer)
        
        buttonContainer.snp.makeConstraints { make in
            make.bottom.equalTo(segmentedControl.snp.top).offset(-20)
            make.width.equalTo(segmentedControl)
            make.centerX.equalTo(view)
            make.height.equalTo(50)
        }
        
        for (index, title) in filterOptions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            button.backgroundColor = .clear
            button.setTitleColor(.deepBlue, for: .normal)
            buttonContainer.addArrangedSubview(button)
            filterButtons.append(button)
        }
    }
    
    @objc func filterButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        
        if selectedFilterIndex == index {
            // 取消選擇
            sender.backgroundColor = .clear
            sender.setTitleColor(.deepBlue, for: .normal)
            selectedFilterIndex = nil
            
            // 取消篩選條件，重新加載所有行程數據
            loadTripsData(userId: userId)
            
        } else {
            // 取消之前選擇的按鈕
            if let previousIndex = selectedFilterIndex {
                filterButtons[previousIndex].backgroundColor = .clear
                filterButtons[previousIndex].setTitleColor(.deepBlue, for: .normal)
            }
            
            // 選中當前按鈕
            sender.backgroundColor = .clear
            sender.setTitleColor(.accent, for: .normal)
            selectedFilterIndex = index
            
            // 請求對應 tag 的行程數據並更新畫面
            FirebaseManager.shared.loadTripsByTag(tag: index) { [weak self] trips in
                guard let self = self else { return }
                
                // 遍歷每個行程，檢查是否被收藏
                var bookmarkedTrips: [Trip] = []
                let group = DispatchGroup() // 用於同步處理
                for trip in trips {
                    group.enter()
                    FirebaseManager.shared.isTripBookmarked(forUserId: userId, tripId: trip.id) { isBookmarked in
                        if isBookmarked {
                            bookmarkedTrips.append(trip)
                        }
                        group.leave()
                    }
                }
                
                // 在所有檢查完成後更新表格
                group.notify(queue: .main) {
                    // 更新行程數據，只保留被收藏的行程
                    self.tripsArray = bookmarkedTrips
                    
                    // 根據行程完成狀態更新 `incompleteTripsArray` 和 `completeTripsArray`
                    self.incompleteTripsArray = bookmarkedTrips.filter { !$0.isComplete }
                    self.completeTripsArray = bookmarkedTrips.filter { $0.isComplete }
                    
                    // 更新 tableView
                    self.collectionsTableView.reloadData()
                }
            }
        }
    }

    func resetFilterButtons() {
        // 取消所有篩選按鈕的選取狀態
        for button in filterButtons {
            button.backgroundColor = .clear
            button.setTitleColor(.deepBlue, for: .normal)
        }
        selectedFilterIndex = nil // 重置選取的索引
    }
}

extension CollectionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
            if segmentIndex == 0 {
                return 2
            } else {
                return 1
            }
        }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            if segmentIndex == 0 {
                // "行程" 頁面 section 標題
                if section == 0 {
                    return "未完成"
                } else {
                    return "已完成"
                }
            } else {
                // "日記" 頁面沒有 section 標題
                return nil
            }
        }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentIndex == 0 {
            if section == 0 {
                return incompleteTripsArray.count
            } else {
                return completeTripsArray.count
            }
        } else {
            return postsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = collectionsTableView.dequeueReusableCell(withIdentifier: "collectionsCell", for: indexPath) as? CollectionsTableViewCell
        cell?.selectionStyle = .none
        
        if segmentIndex == 0 {
            if indexPath.section == 0 {
                cell?.titleLabel.text = incompleteTripsArray[indexPath.row].poem.title as? String ?? "Unknown Trip"
                // 檢查行程是否已收藏
                FirebaseManager.shared.isTripBookmarked(forUserId: userId, tripId: incompleteTripsArray[indexPath.row].id as? String ?? "") { isBookmarked in
                    cell?.collectButton.isSelected = isBookmarked
                }
            } else {
                cell?.titleLabel.text = completeTripsArray[indexPath.row].poem.title as? String ?? "Unknown Trip"
                // 檢查行程是否已收藏
                FirebaseManager.shared.isTripBookmarked(forUserId: userId, tripId: completeTripsArray[indexPath.row].id as? String ?? "") { isBookmarked in
                    cell?.collectButton.isSelected = isBookmarked
                }
            }
        } else {
            cell?.titleLabel.text = postsArray[indexPath.row]["title"] as? String
            
            // 檢查貼文是否已收藏
            FirebaseManager.shared.isContentBookmarked(forUserId: "Am5Jsa1tA0IpyXMLuilm", id: postsArray[indexPath.row]["id"] as? String ?? "") { isBookmarked in
                cell?.collectButton.isSelected = isBookmarked
            }
        }
        
        cell?.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if segmentIndex == 0 {
            
            
        } else {
            let post = postsArray[indexPath.row]
            
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
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        let point = sender.convert(CGPoint.zero, to: collectionsTableView)
        
        if let indexPath = collectionsTableView.indexPathForRow(at: point) {
            var id = String()
            let userId = "Am5Jsa1tA0IpyXMLuilm"
            
            if segmentIndex == 0 {
                id = tripsArray[indexPath.row].id as? String ?? ""
            } else {
                id = postsArray[indexPath.row]["id"] as? String ?? ""
            }
            
            if sender.isSelected {
                // 收藏操作
                FirebaseManager.shared.updateUserCollections(userId: userId, id: id) { success in
                    if success {
                        print("收藏成功")
                    } else {
                        print("收藏失敗")
                    }
                }
            } else {
                if segmentIndex == 0 {
                    // 取消收藏行程
                    FirebaseManager.shared.removeTripBookmark(forUserId: userId, tripId: id) { success in
                        if success {
                            print("取消行程收藏成功")
                            self.bookmarkTripIdArray.removeAll { $0 == id }
                            self.tripsArray.remove(at: indexPath.row)
                            self.collectionsTableView.reloadData()
                        } else {
                            print("取消收藏失敗")
                        }
                    }
                } else {
                    // 取消收藏貼文
                    FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: id) { success in
                        if success {
                            print("取消收藏成功")
                            self.bookmarkPostIdArray.removeAll { $0 == id }
                            self.postsArray.remove(at: indexPath.row)
                            self.collectionsTableView.reloadData()
                        } else {
                            print("取消收藏失敗")
                        }
                    }
                }
            }
        }
    }
}
