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
    
    let db = Firestore.firestore()
    var selectedButton: UIButton?
    var bottomSheetManager: BottomSheetManager?
    var allTripIds = [String]()
    var selectedPoem: Poem?
    var filteredPosts = [[String: Any]]()
    var cityGroupedPoems = [String: [[String: Any]]]()
    var tableView: UITableView!
    var emptyStateLabel: UILabel!
    var scrollView: UIScrollView!
    let currentUserId = UserDefaults.standard.string(forKey: "userId")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.navigationItem.largeTitleDisplayMode = .never
        setupEmptyStateLabel()
        setupScrollView()
        setupTableView()
        self.navigationItem.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.deepBlue
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(50)
        }
        
        updateScrollViewButtons() // 動態生成按鈕
    }
    
    func updateScrollViewButtons() {
        var buttonX: CGFloat = 10
        let buttonPadding: CGFloat = 10
        let buttonHeight: CGFloat = 40
        
        // 打印 scrollView 的 frame
        print("------ScrollView frame before adding buttons: \(scrollView.frame)")
        
        // 创建按钮并添加到 scrollView
        for (index, city) in cityGroupedPoems.keys.enumerated() {
            print("/////", cityGroupedPoems.keys)
            let button = UIButton(type: .system)
            button.setTitle(city, for: .normal)
            button.titleLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 20)
            //            button.titleLabel?.textColor = .deepBlue
            button.layer.borderColor = UIColor.deepBlue.cgColor
            button.layer.borderWidth = 1
            button.backgroundColor = .white
            button.setTitleColor(.deepBlue, for: .normal)
            button.layer.cornerRadius = 20
            button.tag = index
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            
            // 设置按钮的宽度
            let buttonWidth = max(80, city.size(withAttributes: [.font: button.titleLabel?.font ?? UIFont.systemFont(ofSize: 17)]).width + 20)
            button.frame = CGRect(x: buttonX, y: 5, width: buttonWidth, height: buttonHeight)
            buttonX += buttonWidth + buttonPadding
            
            print("Adding button with title: \(city), Frame: \(button.frame)")
            
            scrollView.addSubview(button)
        }
        
        // 更新 scrollView 的 contentSize
        scrollView.contentSize = CGSize(width: buttonX, height: buttonHeight)
        print("ScrollView contentSize: \(scrollView.contentSize)")
    }
    
    @objc func filterButtonTapped(_ sender: UIButton) {
        if selectedButton == sender {
            // 如果再次點擊同一個按鈕，顏色重設為 .deepBlue 並返回頂部
            sender.setTitleColor(.deepBlue, for: .normal)
            selectedButton = nil
            tableView.setContentOffset(.zero, animated: true)
        } else {
            // 將之前的按鈕顏色還原為 .deepBlue
            selectedButton?.setTitleColor(.deepBlue, for: .normal)
            
            // 將新選中的按鈕設為 .accent 顏色
            sender.setTitleColor(.accent, for: .normal)
            selectedButton = sender
            
            // 滾動到對應的 section
            let section = sender.tag
            let headerRect = tableView.rectForHeader(inSection: section)
            let safeAreaTopInset = tableView.safeAreaInsets.top
            let offsetY = max(headerRect.origin.y - safeAreaTopInset, 0)
            
            DispatchQueue.main.async {
                self.tableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
            }
        }
    }
    
    func setupEmptyStateLabel() {
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "現在還沒有這首詩的日記"
        emptyStateLabel.textColor = .lightGray
        emptyStateLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
        view.addSubview(emptyStateLabel)
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
    }
    
    func updateEmptyState() {
        let hasData = !cityGroupedPoems.isEmpty
        emptyStateLabel.isHidden = hasData
        tableView.isHidden = !hasData
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
            make.top.equalTo(scrollView.snp.bottom)
            make.leading.trailing.equalTo(view).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cityGroupedPoems.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let city = Array(cityGroupedPoems.keys)[section]
        return cityGroupedPoems[city]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as? UserTableViewCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let city = Array(cityGroupedPoems.keys)[indexPath.section]
        if let post = cityGroupedPoems[city]?[indexPath.row] {
            cell.configure(with: post)
            
            if let postOwnerId = post["userId"] as? String {
                FirebaseManager.shared.fetchUserData(userId: postOwnerId) { result in
                    switch result {
                    case .success(let data):
                        if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                            DispatchQueue.main.async {
                                cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                            }
                        }
                        cell.userNameLabel.text = data["userName"] as? String
                        
                        FirebaseManager.shared.loadAwardTitle(forUserId: postOwnerId) { (result: Result<(String, Int), Error>) in
                            switch result {
                            case .success(let (awardTitle, item)):
                                let title = awardTitle
                                cell.awardLabelView.updateTitle(awardTitle)
                                DispatchQueue.main.async {
                                    AwardStyleManager.updateTitleContainerStyle(
                                        forTitle: awardTitle,
                                        item: item,
                                        titleContainerView: cell.awardLabelView,
                                        titleLabel: cell.awardLabelView.titleLabel,
                                        dropdownButton: nil
                                    )
                                }
                                
                            case .failure(let error):
                                print("獲取稱號失敗: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Error loading user data: \(error.localizedDescription)")
                    }
                }
            }
            
            FirebaseManager.shared.loadPosts { posts in
                let filteredPosts = posts.filter { filteredPost in
                    return filteredPost["id"] as? String == post["id"] as? String
                }
                if let matchedPost = filteredPosts.first,
                   let likesAccount = matchedPost["likesAccount"] as? [String] {
                    
                    DispatchQueue.main.async {
                        cell.likeCountLabel.text = String(likesAccount.count)
                        cell.likeButton.isSelected = likesAccount.contains(self.currentUserId ?? "") // 依據是否按讚來設置狀態
                    }
                } else {
                    DispatchQueue.main.async {
                        cell.likeCountLabel.text = "0"
                        cell.likeButton.isSelected = false // 如果沒有按讚，設置為未選中
                    }
                }
            }
            
        }
        cell.likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        cell.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        
        
        cell.containerView.layer.borderColor = UIColor.deepBlue.cgColor
        cell.containerView.layer.borderWidth = 2
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = Array(cityGroupedPoems.keys)[indexPath.section] // 根據 section 取得城市名稱
        guard let post = cityGroupedPoems[city]?[indexPath.row] else { return } // 從對應城市中取得文章
        
        let articleVC = ArticleViewController()
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                // 配置文章詳情
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
                
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(articleVC, animated: true)
                }
            } else {
                print("未找到對應的 userName")
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 创建一个 UIView 作为 section 的 header
        let headerView = UIView()
        headerView.backgroundColor = .backgroundGray // 设置背景色
        
        // 创建 UILabel 来显示标题
        let titleLabel = UILabel()
        titleLabel.text = Array(cityGroupedPoems.keys)[section]
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        titleLabel.textColor = .deepBlue // 自定义文字颜色
        
        headerView.addSubview(titleLabel)
        
        // 使用 Auto Layout 进行布局
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16), // 左边有间距
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor) // 垂直居中
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40 // 自定义的 header 高度
    }
    
    // MARK: - 加載數據
    func loadFilteredPosts(cityToTrips: [String: [String]], completion: @escaping ([String: [[String: Any]]]) -> Void) {
        FirebaseManager.shared.loadPosts { [weak self] postsArray in
            guard let self = self else { return }
            
            var cityGroupedPosts: [String: [[String: Any]]] = [:]
            
            for (city, tripIds) in cityToTrips {
                let cityPosts = postsArray.filter { postData in
                    guard let tripId = postData["tripId"] as? String else { return false }
                    return tripIds.contains(tripId)
                }
                
                if !cityPosts.isEmpty {
                    cityGroupedPosts[city] = cityPosts
                }
            }
            
            print("City Grouped Posts: \(cityGroupedPosts)")
            completion(cityGroupedPosts)
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
                    print("++++++    ", poemsArray)
                    
                    var cityToTrips: [String: [String]] = [:]
                    
                    for poem in poemsArray {
                        if let city = poem["city"] as? String,
                           let tripId = poem["tripId"] as? String {
                            
                            if var existingTrips = cityToTrips[city] {
                                existingTrips.append(tripId)
                                cityToTrips[city] = existingTrips
                            } else {
                                cityToTrips[city] = [tripId]
                            }
                        }
                    }
                    
                    print("City to Trips Mapping: \(cityToTrips)")
                    
                    self.loadFilteredPosts(cityToTrips: cityToTrips) { cityGroupedPosts in
                        self.cityGroupedPoems = cityGroupedPosts
                        self.updateEmptyState()
                        self.updateScrollViewButtons()
                        self.tableView.reloadData()
                    }
                } else {
                    self.updateEmptyState()
                }
            }
        }
    }
}

extension PoemPostViewController {
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()

        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point),
           let cell = tableView.cellForRow(at: indexPath) as? UserTableViewCell {
            
            // 取得貼文資料
            let postData = cityGroupedPoems[Array(cityGroupedPoems.keys)[indexPath.section]]?[indexPath.row]
            let postId = postData?["id"] as? String ?? ""

            guard let userId = self.currentUserId else { return }

            // 儲存按讚資料
            saveLikeData(postId: postId, userId: userId, isLiked: sender.isSelected) { success in
                if success {
                    // 重新載入按讚數據
                    FirebaseManager.shared.loadPosts { posts in
                        let filteredPosts = posts.filter { post in
                            return post["id"] as? String == postId
                        }
                        if let matchedPost = filteredPosts.first,
                           let likesAccount = matchedPost["likesAccount"] as? [String] {
                            
                            // 在主線程更新 UI
                            DispatchQueue.main.async {
                                cell.likeCountLabel.text = String(likesAccount.count)
                                cell.likeButton.isSelected = likesAccount.contains(userId)
                            }
                        } else {
                            DispatchQueue.main.async {
                                cell.likeCountLabel.text = "0"
                                cell.likeButton.isSelected = false
                            }
                        }
                    }
                } else {
                    // 如果儲存失敗，還原按鈕狀態
                    DispatchQueue.main.async {
                        sender.isSelected.toggle()
                    }
                }
            }
        }
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let postData = cityGroupedPoems[Array(cityGroupedPoems.keys)[indexPath.section]]?[indexPath.row]
            let postId = postData?["id"] as? String ?? ""
            guard let userId = self.currentUserId else { return }
            
            var bookmarkAccount = postData?["bookmarkAccount"] as? [String] ?? []
            
            if sender.isSelected {
                // 取消收藏
                bookmarkAccount.removeAll { $0 == userId }
                FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                    if success {
                        self.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                            if let error = error {
                                print("Failed to update bookmarkAccount: \(error)")
                            }
                        }
                    }
                }
            } else {
                // 新增收藏
                if !bookmarkAccount.contains(userId) {
                    bookmarkAccount.append(userId)
                }
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        self.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
                            if let error = error {
                                print("Failed to update bookmarkAccount: \(error)")
                            }
                        }
                    }
                }
            }
            
            // 切換按鈕狀態
            sender.isSelected.toggle()
        }
    }
    func saveLikeData(postId: String, userId: String, isLiked: Bool, completion: @escaping (Bool) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        postRef.getDocument { document, error in
            if let document = document, document.exists {
                guard let postOwnerId = document.data()?["userId"] as? String else {
                    completion(false)
                    return
                }
                
                if isLiked {
                    postRef.updateData([
                        "likesAccount": FieldValue.arrayUnion([userId])
                    ]) { error in
                        if let error = error {
                            completion(false)
                        } else {
                            completion(true)
                            
                            FirebaseManager.shared.fetchUserData(userId: userId) { result in
                                switch result {
                                case .success(let data):
                                    let userName = data["userName"] as? String ?? ""
                                    FirebaseManager.shared.saveNotification(
                                        to: postOwnerId,
                                        from: userId,
                                        postId: postId,
                                        type: 0,
                                        subType: nil, title: "你的日記被按讚了！",
                                        message: "\(userName) 按讚了你的日記",
                                        actionUrl: nil, priority: 0
                                    ) { result in
                                        switch result {
                                        case .success:
                                            print("通知发送成功")
                                        case .failure(let error):
                                            print("通知发送失败: \(error.localizedDescription)")
                                        }
                                    }
                                case .failure(let error):
                                    print("加載貼文發布者大頭貼失敗: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                } else {
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
        }
        
    }
}
