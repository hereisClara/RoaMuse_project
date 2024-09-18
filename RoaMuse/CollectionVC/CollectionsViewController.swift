//
//  CollectionsViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit
import SnapKit

class CollectionsViewController: UIViewController {
    
    let segmentedControl = UISegmentedControl(items: ["行程", "日記"])
    let collectionsTableView = UITableView()
    var bookmarkPostIdArray = [String]()
    var bookmarkTripIdArray = [String]()
    var postsArray = [[String: Any]]()
    var tripsArray = [Trip]() // 更新為存儲從 Firebase 獲取的行程
    var segmentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        setupUI()
        setupTableView()
        setupSegmentedControl()
        loadInitialData()
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
        loadInitialData()
    }
    
    func loadInitialData() {
        if segmentIndex == 0 {
            loadTripsData(userId: "Am5Jsa1tA0IpyXMLuilm")
        } else {
            loadPostsData()
        }
    }
    
    // 加載收藏的行程
    func loadTripsData(userId: String) {
        self.tripsArray.removeAll()

        FirebaseManager.shared.loadBookmarkTripIDs(forUserId: userId) { [weak self] (tripIds: [String]) in
            guard let self = self else { return }
            self.bookmarkTripIdArray = tripIds
            print("Bookmarked Trip IDs: \(tripIds)") // Debugging

            if !tripIds.isEmpty {
                // 根據 tripIds 從 Firebase 中加載收藏的行程
                FirebaseManager.shared.loadBookmarkedTrips(tripIds: tripIds) { [weak self] (trips: [Trip]) in
                    guard let self = self else { return }
                    self.tripsArray = trips
                    self.collectionsTableView.reloadData()
                }
            } else {
                print("No trips found in bookmarks.") // Debugging
                self.collectionsTableView.reloadData() // 確保即使沒有數據也更新 UI
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
                }
            } else {
                print("No posts found in bookmarks.") // Debugging
                self.collectionsTableView.reloadData() // 確保即使沒有數據也更新 UI
            }
        }
    }
}

extension CollectionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentIndex == 0 {
            return tripsArray.count
        } else {
            return postsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = collectionsTableView.dequeueReusableCell(withIdentifier: "collectionsCell", for: indexPath) as? CollectionsTableViewCell
        cell?.selectionStyle = .none
        
        if segmentIndex == 0 {
            cell?.titleLabel.text = tripsArray[indexPath.row].poem.title as? String ?? "Unknown Trip"
            
            // 檢查行程是否已收藏
            FirebaseManager.shared.isTripBookmarked(forUserId: "Am5Jsa1tA0IpyXMLuilm", tripId: tripsArray[indexPath.row].id as? String ?? "") { isBookmarked in
                cell?.collectButton.isSelected = isBookmarked
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
