//
//  CollectionsViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class CollectionsViewController: UIViewController {
    
    let dataManager = DataManager()
    let segmentedControl = UISegmentedControl(items: ["行程", "日記"])
    let collectionsTableView = UITableView()
    var currentDataSource: [String] = []
    var bookmarkPostIdArray = [String]()
    var bookmarkTripIdArray = [String]()
    var postsArray = [[String: Any]]()
    var tripsArray = [Trip]()
    var segmentIndex = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentIndex = 0
        loadData()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        dataManager.loadJSONData()
        dataManager.loadPlacesJSONData()
        collectionsTableView.register(CollectionsTableViewCell.self, forCellReuseIdentifier: "collectionsCell")
        collectionsTableView.delegate = self
        collectionsTableView.dataSource = self
        setupUI()
        setupTableView()
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        print(dataManager.trips)
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
    
    @objc func segmentedControlChanged(_ sender: UISegmentedControl) {
        print("選擇了 \(sender.selectedSegmentIndex) 索引的項目")
        switch sender.selectedSegmentIndex {
            //                行程
        case 0:
            print("行程被選中")
            segmentIndex = 0
            loadData()
            //                日記
        case 1:
            print("日記被選中")
            segmentIndex = 1
            loadData()
        default:
            break
        }
    }
    
    func loadData() {
        
        if segmentIndex == 0 {
            bookmarkTripIdArray = []
            fetchBookmarkTrip(forUserId: "qluFSSg8P1fGmWfXjOx6")
            
        } else {
            bookmarkPostIdArray = []
            fetchBookmarkPost(forUserId: "qluFSSg8P1fGmWfXjOx6")
        }
    }
    //    找到用戶收藏的文章id
    func fetchBookmarkPost(forUserId userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let bookmarkPost = document.data()?["bookmarkPost"] as? [String] {
                    
                    self.bookmarkPostIdArray.append(contentsOf: bookmarkPost)
                    self.fetchPosts(forPostIds: self.bookmarkPostIdArray)
                } else {
                    print("沒有找到 bookmarkPost 字段")
                }
            } else {
                print("用戶文檔不存在：\(error?.localizedDescription ?? "未知錯誤")")
            }
        }
    }
    
    //    用id找到文章
    
    func fetchPosts(forPostIds postIds: [String]) {
        let db = Firestore.firestore()
        
        // 清空之前的資料
        postsArray = [[String: Any]]()

        // 迭代每個 postId 並從 posts 集合中查詢
        for postId in postIds {
            let postRef = db.collection("posts").document(postId)
            
            postRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let postData = document.data() ?? [:]
                    self.postsArray.append(postData) // 將查到的文章資料存入 postsArray
//                    print(self.postsArray)
                    // 重載表格視圖，這裡的重載應在所有文章都查找完之後進行
                    self.collectionsTableView.reloadData()
                    
                } else {
                    print("找不到 postId 為 \(postId) 的文章: \(error?.localizedDescription ?? "未知錯誤")")
                }
            }
        }
    }
    
    func fetchBookmarkTrip(forUserId userId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let bookmarkTrip = document.data()?["bookmarkTrip"] as? [String] {
                    self.bookmarkTripIdArray.append(contentsOf: bookmarkTrip)
                    print("=======", self.bookmarkTripIdArray)
                    self.getCollectTrip(tripId: self.bookmarkTripIdArray)
                    self.collectionsTableView.reloadData()
                    
                } else {
                    print("沒有找到 bookmarkTrip 字段")
                }
            } else {
                print("用戶文檔不存在：\(error?.localizedDescription ?? "未知錯誤")")
            }
        }
    }
    
    func getCollectTrip(tripId: [String]) {
        
        tripsArray = [Trip]()
        
        for id in bookmarkTripIdArray {
            
            for trip in dataManager.trips {
                print("=====")
                if id == trip.id {
                    print(id)
                    print(trip.id)
                    tripsArray.append(trip)
                    
                }
                
            }
            
        }
        
        print("--------", tripsArray)
    }
}

extension CollectionsViewController: UITableViewDelegate, UITableViewDataSource {
    
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
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
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
        
        guard let cell = cell else { return UITableViewCell() }
        
        cell.selectionStyle = .none
        
        if segmentIndex == 0 {
            cell.titleLabel.text = tripsArray[indexPath.row].poem.title
        } else {
            cell.titleLabel.text = postsArray[indexPath.row]["title"] as? String
        }
        
        return cell
    }
    
}
