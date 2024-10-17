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
import CoreLocation

class CollectionsViewController: UIViewController {
    
    let locationManager = LocationManager()
    var segmentedControl = UISegmentedControl()
    let collectionsTableView = UITableView()
    var bookmarkPostIdArray = [String]()
    var bookmarkTripIdArray = [String]()
    var postsArray = [[String: Any]]()
    var tripsArray = [Trip]()
    var segmentIndex = 0
    let popupView = PopUpView()
    var incompleteTripsArray = [Trip]()
    var completeTripsArray = [Trip]()
    var filterButtons: [UIButton] = []
    var selectedFilterIndex: Int?
    let mainContainer = UIView()
    let buttonsBackground = UIView()
    let magnifierBackground = UIView()
    let buttonContainer = UIStackView()
    var isExpanded = false
    var mainContainerWidthConstraint: Constraint?
    var poemIdsInCollectionTrip = [String]()
    var incompletesPoemTitleArray: [String] = []
    var completesPoemTitleArray: [String] = []
    var selectedTrip: Trip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backButtonTitle = ""
        self.title = "收藏"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, // 修改顏色
                .font: customFont // 設置字體
            ]
        }
        popupView.delegate = self
        loadInitialData()
        setupUI()
        setupTableView()
        setupSegmentedControl()
        setupRefreshControl()
        setupFilterButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadInitialData()
        setupNavigationBarStyle()
    }
    
    private func setupNavigationBarStyle() {
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground() // 或根据需要设置
            navBarAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue,
                .font: customFont
            ]

            self.navigationItem.standardAppearance = navBarAppearance
            self.navigationItem.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    func setupUI() {
        view.addSubview(segmentedControl)
        
        segmentedControl.layer.cornerRadius = 25
        segmentedControl.clipsToBounds = true
        segmentedControl.layer.masksToBounds = true
        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(70)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(50)
        }
    }
    
    func setupSegmentedControl() {
        segmentedControl = UISegmentedControl(items: ["行程", "日記"])
        segmentedControl.selectedSegmentIndex = 0
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.deepBlue,
            .font: UIFont(name: "NotoSerifHK-Black", size: 20)
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "NotoSerifHK-Black", size: 20)
        ]
        
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        segmentedControl.backgroundColor = UIColor.clear
        segmentedControl.selectedSegmentTintColor = UIColor.deepBlue
        
        segmentedControl.layer.cornerRadius = 25
        segmentedControl.layer.borderWidth = 2
        segmentedControl.layer.borderColor = UIColor.deepBlue.cgColor
        segmentedControl.clipsToBounds = true
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        
        view.addSubview(segmentedControl)
        
        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(70)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(50)
        }
    }
    
    func setupTableView() {
        view.addSubview(collectionsTableView)
        collectionsTableView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(segmentedControl.snp.bottom).offset(15)
            make.width.equalTo(view).multipliedBy(0.9)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
        }
        
        collectionsTableView.layer.cornerRadius = 10
        collectionsTableView.layer.masksToBounds = true
        
        collectionsTableView.separatorStyle = .none
        collectionsTableView.backgroundColor = .clear
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
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        if segmentIndex == 0 {
            loadTripsData(userId: userId)
        } else {
            loadPostsData()
        }
    }
    
    func loadTripsData(userId: String) {

        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        self.incompleteTripsArray.removeAll()
        self.completeTripsArray.removeAll()
        self.incompletesPoemTitleArray.removeAll()
        self.completesPoemTitleArray.removeAll()

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
            
            let bookmarkTripIds = data["bookmarkTrip"] as? [String] ?? []
            let completedTripIds = data["completedTrip"] as? [String] ?? []
            
            let incompleteTripIds = bookmarkTripIds.filter { !completedTripIds.contains($0) }
            let completeTripIds = bookmarkTripIds.filter { completedTripIds.contains($0) }
            
            let parentDispatchGroup = DispatchGroup()
            
            parentDispatchGroup.enter()
            FirebaseManager.shared.loadBookmarkedTrips(tripIds: incompleteTripIds) { [weak self] incompleteTrips in
                guard let self = self else { parentDispatchGroup.leave(); return }
                self.incompleteTripsArray = incompleteTrips
                self.incompletesPoemTitleArray = Array(repeating: "", count: incompleteTrips.count)
                
                let dispatchGroup = DispatchGroup()
                
                for (index, trip) in incompleteTrips.enumerated() {
                    dispatchGroup.enter()
                    FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                        let poemTitle = poem.title
                        self.incompletesPoemTitleArray[index] = poemTitle
                        PoemCollectionManager.shared.addPoemId(trip.poemId)
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    parentDispatchGroup.leave()
                }
            }
            
            // 处理已完成行程
            parentDispatchGroup.enter()
            FirebaseManager.shared.loadBookmarkedTrips(tripIds: completeTripIds) { [weak self] completeTrips in
                guard let self = self else { parentDispatchGroup.leave(); return }
                self.completeTripsArray = completeTrips
                self.completesPoemTitleArray = Array(repeating: "", count: completeTrips.count)
                
                let dispatchGroup = DispatchGroup()
                
                for (index, trip) in completeTrips.enumerated() {
                    dispatchGroup.enter()
                    FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                        let poemTitle = poem.title
                        self.completesPoemTitleArray[index] = poemTitle
                        PoemCollectionManager.shared.addPoemId(trip.poemId)
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    parentDispatchGroup.leave()
                }
            }
            
            // 当所有数据加载完成后，刷新表格视图
            parentDispatchGroup.notify(queue: .main) {
                self.collectionsTableView.reloadData()
                self.collectionsTableView.mj_header?.endRefreshing()
            }
        }
    }

    // 加載收藏的文章
    func loadPostsData() {

        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        self.postsArray.removeAll()
        
        FirebaseManager.shared.loadBookmarkPostIDs(forUserId: userId) { [weak self] postIds in
            guard let self = self else { return }
            self.bookmarkPostIdArray = postIds
            print("Bookmarked Post IDs: \(postIds)") // Debugging
            
            if !postIds.isEmpty {

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
    
    func setupFilterButtons() {
        // 主容器
        view.addSubview(mainContainer)
        mainContainer.snp.makeConstraints { make in
            make.leading.equalTo(segmentedControl.snp.leading) // 藍色圓底的 leading 和 segmentedControl 的 leading 對齊
            make.bottom.equalTo(segmentedControl.snp.top).offset(-15) // 底部距離 segmentControl 30
            make.height.equalTo(50)
            self.mainContainerWidthConstraint = make.width.equalTo(50).constraint
        }
        
        // 白色背景，開始時隱藏
        buttonsBackground.backgroundColor = .white
        buttonsBackground.layer.cornerRadius = 25
        buttonsBackground.layer.masksToBounds = true
        mainContainer.addSubview(buttonsBackground)
        
        buttonsBackground.snp.makeConstraints { make in
            make.leading.equalTo(mainContainer)
            make.trailing.equalTo(mainContainer)
            make.height.equalTo(50)
            make.centerY.equalTo(mainContainer)
        }
        buttonsBackground.isHidden = true
        
        magnifierBackground.backgroundColor = .deepBlue
        magnifierBackground.layer.cornerRadius = 25
        magnifierBackground.layer.masksToBounds = true
        mainContainer.addSubview(magnifierBackground)
        
        magnifierBackground.snp.makeConstraints { make in
            make.leading.equalTo(mainContainer)
            make.width.height.equalTo(50)
            make.centerY.equalTo(mainContainer)
        }
        
        // 放大鏡圖標
        let magnifierIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        magnifierIcon.tintColor = .white
        magnifierBackground.addSubview(magnifierIcon)
        
        magnifierIcon.snp.makeConstraints { make in
            make.center.equalTo(magnifierBackground)
            make.width.height.equalTo(24)
        }
        
        let magnifierTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleFilterButtons))
        magnifierBackground.addGestureRecognizer(magnifierTapGesture)
        
        buttonContainer.axis = .horizontal
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 15
        buttonsBackground.addSubview(buttonContainer)
        
        buttonContainer.snp.makeConstraints { make in
            make.edges.equalTo(buttonsBackground).inset(10)
            make.leading.equalTo(magnifierBackground.snp.trailing).offset(15) // 設定距離藍色圓底15
        }
        
        // 添加篩選按鈕
        let filterOptions = ["奇險派", "浪漫派", "田園派"]
        
        for (index, title) in filterOptions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.setTitleColor(.deepBlue, for: .normal)
            button.backgroundColor = .clear
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            buttonContainer.addArrangedSubview(button)
            filterButtons.append(button)
        }
    }
    
    func filterPostsByTrips(trips: [Trip]) {
        let tripIds = trips.map { $0.id }
        
        FirebaseManager.shared.loadPosts { [weak self] posts in
            guard let self = self else { return }
            
            guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
            
            FirebaseManager.shared.loadBookmarkPostIDs(forUserId: userId) { bookmarkedPostIds in
                self.postsArray = posts.filter { post in
                    if let postTripId = post["tripId"] as? String, let postId = post["id"] as? String {
                        return tripIds.contains(postTripId) && bookmarkedPostIds.contains(postId)
                    }
                    return false
                }
                
                DispatchQueue.main.async {
                    self.collectionsTableView.reloadData()
                }
            }
        }
    }
    
    func resetFilterButtons() {
        
        for button in filterButtons {
            button.backgroundColor = .clear
            button.setTitleColor(.deepBlue, for: .normal)
        }
        selectedFilterIndex = nil
    }
}

extension CollectionsViewController {
    
    @objc func toggleFilterButtons() {
        if isExpanded {
            // 收合動畫
            UIView.animate(withDuration: 0.3, animations: {
                self.mainContainerWidthConstraint?.update(offset: 50)
                self.buttonsBackground.alpha = 1 // 淡出動畫
                self.view.layoutIfNeeded()
            }) { _ in
                // 完成動畫後隱藏按鈕背景
                self.buttonsBackground.isHidden = true
            }
        } else {
            // 展開動畫
            buttonsBackground.isHidden = false // 顯示按鈕背景
            buttonsBackground.alpha = 1 // 從透明開始
            UIView.animate(withDuration: 0.3, animations: {
                // 將按鈕背景展開到預定寬度
                self.mainContainerWidthConstraint?.update(offset: self.segmentedControl.frame.width) // 展開的寬度可以根據需要調整
                self.buttonsBackground.alpha = 1 // 淡入動畫
                self.view.layoutIfNeeded()
            })
        }
        isExpanded.toggle() // 切換展開狀態
    }
    
    @objc func filterButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        // 檢查是否點擊了相同的篩選按鈕，如果是則重置
        if selectedFilterIndex == index {
            sender.setTitleColor(.deepBlue, for: .normal)
            selectedFilterIndex = nil
            loadTripsData(userId: userId)
            loadPostsData()
        } else {
            // 重置之前的按鈕顏色
            if let previousIndex = selectedFilterIndex {
                if previousIndex < filterButtons.count {
                    filterButtons[previousIndex].setTitleColor(.deepBlue, for: .normal)
                }
            }
            sender.setTitleColor(.accent, for: .normal)
            selectedFilterIndex = index
            
            // 根據 tag 加載行程
            FirebaseManager.shared.loadTripsByTag(tag: index) { [weak self] trips in
                guard let self = self else { return }
                
                FirebaseManager.shared.loadBookmarkTripIDs(forUserId: userId) { bookmarkedTrips in
                    FirebaseManager.shared.fetchUserData(userId: userId) { result in
                        switch result {
                        case .success(let userData):
                            let completedTrips = userData["completedTrip"] as? [String] ?? []
                            let bookmarkedTrips = trips.filter { bookmarkedTrips.contains($0.id) }
                            self.incompleteTripsArray = bookmarkedTrips.filter { !completedTrips.contains($0.id) }
                            self.completeTripsArray = bookmarkedTrips.filter { completedTrips.contains($0.id) }
                            
                            // 邊界檢查，確保不會訪問越界的數組
                            if !self.incompleteTripsArray.isEmpty {
                                for (index, trip) in self.incompleteTripsArray.enumerated() {
                                    FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                                        DispatchQueue.main.async {
                                            if index < self.incompleteTripsArray.count {
                                                self.incompletesPoemTitleArray[index] = poem.title
                                                self.collectionsTableView.reloadData()
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if !self.completeTripsArray.isEmpty {
                                for (index, trip) in self.completeTripsArray.enumerated() {
                                    FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                                        DispatchQueue.main.async {
                                            // 檢查 index 是否在邊界內
                                            if index < self.completeTripsArray.count {
                                                self.completesPoemTitleArray[index] = poem.title
                                                self.collectionsTableView.reloadData()
                                            }
                                        }
                                    }
                                }
                            }
                            
                            DispatchQueue.main.async {
                                if !self.incompleteTripsArray.isEmpty {
                                }
                                self.collectionsTableView.reloadData()
                            }
                            
                        case .failure(let error):
                            print("Failed to fetch user data: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if segmentIndex == 0 {
            let headerView = UIView()
            headerView.backgroundColor = UIColor.backgroundGray // 設定背景色
            let label = UILabel()
            headerView.addSubview(label)
            label.font = UIFont(name: "NotoSerifHK-Black", size: 22)
            label.textColor = UIColor.deepBlue
            label.text = section == 0 ? "未完成" : "已完成"
            label.snp.makeConstraints { make in
                make.leading.equalTo(headerView).offset(16)
                make.centerY.equalTo(headerView)
            }
            
            return headerView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if segmentIndex == 0 {
            return 35
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
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
        cell?.backgroundColor = .clear
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return UITableViewCell() }
        
        if segmentIndex == 0 {

            if indexPath.section == 0 {
                guard indexPath.row < incompleteTripsArray.count,
                                  indexPath.row < incompletesPoemTitleArray.count else {
                                return UITableViewCell() // 如果數據尚未加載，返回一個空的 UITableViewCell
                            }
                let trip = incompleteTripsArray[indexPath.row]
                let poemTitle = incompletesPoemTitleArray[indexPath.row]
                cell?.titleLabel.text = poemTitle.isEmpty ? "加载中..." : poemTitle
                FirebaseManager.shared.isTripBookmarked(forUserId: userId, tripId: trip.id) { isBookmarked in
                    DispatchQueue.main.async {
                        cell?.collectButton.isSelected = isBookmarked
                    }
                }
            } else {
                guard indexPath.row < completeTripsArray.count,
                                  indexPath.row < completesPoemTitleArray.count else {
                                return UITableViewCell() // 如果數據尚未加載，返回一個空的 UITableViewCell
                            }
                let trip = completeTripsArray[indexPath.row]
                let poemTitle = completesPoemTitleArray[indexPath.row]
                cell?.titleLabel.text = poemTitle.isEmpty ? "加载中..." : poemTitle
                FirebaseManager.shared.isTripBookmarked(forUserId: userId, tripId: trip.id) { isBookmarked in
                    DispatchQueue.main.async {
                        cell?.collectButton.isSelected = isBookmarked
                    }
                }
            }
        } else {
            cell?.titleLabel.text = postsArray[indexPath.row]["title"] as? String ?? "无标题"
            
            FirebaseManager.shared.isContentBookmarked(forUserId: userId, id: postsArray[indexPath.row]["id"] as? String ?? "") { isBookmarked in
                DispatchQueue.main.async {
                    cell?.collectButton.isSelected = isBookmarked
                }
            }
        }
        
        cell?.collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if segmentIndex == 0 {
            let trip: Trip
            
            if indexPath.section == 0 {
                trip = incompleteTripsArray[indexPath.row]
            } else {
                trip = completeTripsArray[indexPath.row]
            }
            
            if let currentLocation = locationManager.currentLocation {
                let dispatchGroup = DispatchGroup()
                var places: [Place] = []
                
                for placeId in trip.placeIds {
                    dispatchGroup.enter()
                    FirebaseManager.shared.loadPlaceById(placeId: placeId) { place in
                        if let place = place {
                            places.append(place)
                        } else {
                            print("未能加載位置 ID: \(placeId)")
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    // 確保 places 不為空
                    if places.isEmpty {
                        print("未找到有效的地點數據，無法計算路徑時間。")
                        return
                    }
                    LocationService.shared.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: places) { totalTravelTime, routes in
                        let tripDetailVC = TripDetailViewController()
                        tripDetailVC.trip = trip
                        
                        // 設置總路徑時間
                        if let totalTravelTime = totalTravelTime, let routes = routes {
                            tripDetailVC.totalTravelTime = totalTravelTime
                            
                            // 創建導航指令數列
                            var nestedInstructions = [[String]]()
                            for route in routes {
                                var stepInstructions = [String]()
                                for step in route.steps {
                                    stepInstructions.append(step.instructions)
                                }
                                nestedInstructions.append(stepInstructions)
                            }
                            tripDetailVC.nestedInstructions = nestedInstructions
                        }
                        
                        // 跳轉到行程詳情頁
                        self.navigationController?.pushViewController(tripDetailVC, animated: true)
                    }
                }
            } else {
                print("無法獲取當前位置")
            }
        } else {
            // 處理文章的選擇
            let post = postsArray[indexPath.row]
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
    }
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        let point = sender.convert(CGPoint.zero, to: collectionsTableView)
        
        if let indexPath = collectionsTableView.indexPathForRow(at: point) {
            var id = String()

            guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
            
            if segmentIndex == 0 {
                if indexPath.section == 0 {
                    if indexPath.row < incompleteTripsArray.count {
                        id = incompleteTripsArray[indexPath.row].id
                    }
                } else if indexPath.section == 1 {
                    if indexPath.row < completeTripsArray.count {
                        id = completeTripsArray[indexPath.row].id
                    }
                }
            } else {
                id = postsArray[indexPath.row]["id"] as? String ?? ""
            }
            
            if sender.isSelected {

                FirebaseManager.shared.updateUserCollections(userId: userId, id: id) { success in
                    if success {
                        print("收藏成功")
                    } else {
                        print("收藏失敗")
                    }
                }
            } else {
                if segmentIndex == 0 {
                    FirebaseManager.shared.removeTripBookmark(forUserId: userId, tripId: id) { success in
                        if success {
                            if indexPath.section == 0 {
                                self.incompleteTripsArray.remove(at: indexPath.row)
                            } else {
                                self.completeTripsArray.remove(at: indexPath.row)
                            }
                            self.collectionsTableView.deleteRows(at: [indexPath], with: .automatic)
                        } else {
                            print("取消收藏失敗")
                        }
                    }
                } else {
                    FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: id) { success in
                        if success {
                            self.bookmarkPostIdArray.removeAll { $0 == id }
                            self.postsArray.remove(at: indexPath.row)
                            self.collectionsTableView.deleteRows(at: [indexPath], with: .automatic)
                        } else {
                            print("取消收藏失敗")
                        }
                    }
                }
            }
        }
    }
}

extension CollectionsViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = selectedTrip
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
}
