
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
    
    let dataManager = DataManager()
    let segmentedControl = UISegmentedControl(items: ["行程", "日記"])
    let collectionsTableView = UITableView()
    var bookmarkPostIdArray = [String]()
    var bookmarkTripIdArray = [String]()
    var postsArray = [[String: Any]]()
    var tripsArray = [Trip]()
    var segmentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        dataManager.loadJSONData()
        dataManager.loadPlacesJSONData()
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
            loadTripsData(userId: "qluFSSg8P1fGmWfXjOx6")
        } else {
            loadPostsData()
        }
    }
    
    func loadTripsData(userId: String) {
        self.tripsArray.removeAll()

        // 使用 FirebaseManager 來載入收藏的行程
        FirebaseManager.shared.loadBookmarkTripIDs(forUserId: userId) { [weak self] tripIds in
            guard let self = self else { return }
            self.bookmarkTripIdArray = tripIds
            print("Bookmarked Trip IDs: \(tripIds)") // 偵錯列印

            if !tripIds.isEmpty {
                // 根據 tripIds 過濾本地行程資料
                self.tripsArray = self.dataManager.trips.filter { tripIds.contains($0.id) }
                self.collectionsTableView.reloadData()
            } else {
                print("No trips found in bookmarks.") // 偵錯列印
                self.collectionsTableView.reloadData() // 確保即使沒有數據也更新 UI
            }
        }
    }

    
    func loadPostsData() {
        // Clear existing posts data to ensure fresh loading
        self.postsArray.removeAll()
        
        // Using FirebaseManager to load bookmarked posts
        FirebaseManager.shared.loadBookmarkPostIDs(forUserId: "qluFSSg8P1fGmWfXjOx6") { [weak self] postIds in
            guard let self = self else { return }
            self.bookmarkPostIdArray = postIds
            print("Bookmarked Post IDs: \(postIds)") // Debugging print
            
            if !postIds.isEmpty {
                // Load posts and filter those that match the bookmarked IDs
                FirebaseManager.shared.loadPosts { posts in
                    self.postsArray = posts.filter { postIds.contains($0["id"] as? String ?? "") }
                    print("Loaded Posts: \(self.postsArray)") // Debugging print
                    self.collectionsTableView.reloadData()
                }
            } else {
                print("No posts found in bookmarks.") // Debugging print
                self.collectionsTableView.reloadData() // Ensure UI updates even if no data
            }
        }
    }
}

extension CollectionsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
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
            cell?.titleLabel.text = tripsArray[indexPath.row].poem.title
        } else {
            cell?.titleLabel.text = postsArray[indexPath.row]["title"] as? String
        }
        
        return cell ?? UITableViewCell()
    }
}
