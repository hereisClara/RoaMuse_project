//
//  HomeViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/11.
//

import UIKit
import SnapKit
import WeatherKit
import CoreLocation
import FirebaseFirestore
import MJRefresh

class HomeViewController: UIViewController {
    
    private let locationManager = LocationManager()
    private let weatherManager = WeatherManager()
    private let randomTripEntryButton = UIButton(type: .system)
    private let recommendRandomTripView = UIView()
    private let homeTableView = UITableView()
    private let popupView = PopUpView()
    
    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        uploadPlaces()
        self.title = "首頁"
        view.backgroundColor = UIColor(resource: .backgroundGray)
        homeTableView.register(PostsTableViewCell.self, forCellReuseIdentifier: "postCell")
        popupView.delegate = self
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        uploadTripData()
        // 从 Firebase 加载 posts
        FirebaseManager.shared.loadPosts { postsArray in
            self.postsArray = postsArray
            self.homeTableView.reloadData()
        }
    }
    
    func setupUI() {
        view.addSubview(recommendRandomTripView)
        
        recommendRandomTripView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(150)
        }
        
        recommendRandomTripView.backgroundColor = .white
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recommendRandomTripView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        randomTripEntryButtonDidTapped()
    }
    
    func setupPullToRefresh() {
        // 添加下拉刷新
        homeTableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshData))
    }
    
    @objc func refreshData() {
        FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
            self.postsArray.insert(contentsOf: newPosts, at: 0)
            self.homeTableView.reloadData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 結束刷新
            self.homeTableView.mj_header?.endRefreshing()
        }
    }
    
    @objc func randomTripEntryButtonDidTapped() {
        // 从 Firebase 加载所有的行程
        FirebaseManager.shared.loadAllTrips { [weak self] trips in
            guard let self = self else { return }
            
            // 随机挑选一个行程
            if let randomTrip = trips.randomElement() {
                self.randomTrip = randomTrip
                
                // 获取随机行程中的地點 ID
                let placeIds = randomTrip.places.map { $0.id }
                
                // 从 Firebase 中加载这些地點的详细信息
                FirebaseManager.shared.loadPlaces(placeIds: placeIds) { places in
                    // 显示弹窗，使用从 Firebase 加载的地點信息
                    self.popupView.showPopup(on: self.view, with: randomTrip)
                    
                    self.popupView.tapCollectButton = { [weak self] in
                        guard let self = self else { return }
                        FirebaseManager.shared.updateUserTripCollections(userId: "Am5Jsa1tA0IpyXMLuilm", tripId: randomTrip.id) { success in
                            if success {
                                print("收藏成功")
                            } else {
                                print("收藏失敗")
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    private func fetchWeather(for location: CLLocation) {
        weatherManager.fetchWeather(for: location) { [weak self] weather in
            DispatchQueue.main.async {
                if let weather = weather {
                    self?.updateWeatherInfo(weather: weather)
                } else {
                    print("無法獲取天氣資訊")
                }
            }
        }
    }
    
    private func updateWeatherInfo(weather: CurrentWeather) {
        print("天氣狀況：\(weather.condition.description)")
        print("溫度：\(weather.temperature.formatted())")
    }
}

extension HomeViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = randomTrip
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        homeTableView.dataSource = self
        homeTableView.delegate = self
        
        view.addSubview(homeTableView)
        homeTableView.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView.snp.bottom).offset(10)
            make.width.equalTo(recommendRandomTripView)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
        }
        homeTableView.backgroundColor = .orange
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = homeTableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostsTableViewCell
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        
        let post = postsArray[indexPath.row]
        
        // 初始化 ArticleViewController
        let articleVC = ArticleViewController()
        
        // 傳遞貼文的資料
        
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
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        // 獲取按鈕點擊所在的行
        let point = sender.convert(CGPoint.zero, to: homeTableView)
        
        if let indexPath = homeTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            let userId = "Am5Jsa1tA0IpyXMLuilm" // 假設為當前使用者ID
            
            // 獲取當前的 bookmarkAccount
            var bookmarkAccount = postData["bookmarkAccount"] as? [String] ?? []
            
            if sender.isSelected {
                // 收藏操作，將 userId 加入 bookmarkAccount
                if !bookmarkAccount.contains(userId) {
                    bookmarkAccount.append(userId)
                }

                // 更新使用者的收藏列表
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        // 更新 Firestore 中的 bookmarkAccount 字段
                        FirebaseManager.shared.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
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
            } else {
                // 取消收藏操作，將 userId 從 bookmarkAccount 中移除
                bookmarkAccount.removeAll { $0 == userId }

                // 移除使用者的收藏
                FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                    if success {
                        // 更新 Firestore 中的 bookmarkAccount 字段
                        FirebaseManager.shared.db.collection("posts").document(postId).updateData(["bookmarkAccount": bookmarkAccount]) { error in
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
            }
        }
    }

    
    func uploadTripData() {
        let db = Firestore.firestore()
        
        // 构建 trip 数据
        let tripData: [String: Any] = [
            "id": "u9QgkOcQsZZh90D6SAfc",
            "isComplete": false,
            "places": [
                [
                    "id": "CbCsS208lUh4OVNXedcB",
                    "isComplete": false
                ],
                [
                    "id": "NsqhxJyJxtv0SPnbDUqi",
                    "isComplete": false
                ],
                [
                    "id": "Q4yAOM6yUTOru6YqExsJ",
                    "isComplete": false
                ]
            ],
            "poem": [
                "original": [
                    "南山何其悲，鬼雨灑空草！",
                    "長安夜半秋，風前幾人老？",
                    "低迷黃昏徑，裊裊青櫟道；",
                    "月午樹無影，一山唯白曉，",
                    "漆炬迎新人，幽壙螢擾擾。"
                ],
                "poetry": "李賀",
                "secretTexts": [
                    "李賀經常騎著一匹瘦馬，帶著小童子邊走邊思索，一旦有了好句子或是來了靈感，便把所想到的靈感急速記錄下來，投進小童子背著的小錦囊裡。",
                    "李賀的詩想像力豐富，意境詭異華麗，常用些險韻奇字。",
                    "李賀只活了短短二十七歲。他經歷了安史之亂帶來的巨大衝擊。"
                ],
                "situationText": [
                    "當細雨輕灑於廣袤的草地上，水霧繚繞，彷彿鬼雨隨風飄落，帶來一種淒美的氛圍。",
                    "夕陽西下，餘暉灑在蜿蜒的山徑間，步道旁的樹木枝葉隨風輕搖。"
                ],
                "title": "〈感諷五首．其三〉",
                "translation": [
                    "南山是多麼的悲涼，鬼雨灑落在空曠的草地上。",
                    "長安的深夜已是秋天，在風中不知多少人已經變老。",
                    "黃昏的路徑彷彿籠罩著一層迷霧，青櫟樹的道路上飄著悠長的微風。",
                    "夜半的月亮高懸，樹木卻無影，整座山上只有白色的晨曦。",
                    "漆黑的火炬迎接著新來的人，幽暗的墓穴中螢火蟲在四處飛舞。"
                ]
            ],
            "season": 2,
            "startTime": 1,
            "tag": 0,
            "weather": 1
        ]
        
        // 上传到 Firestore trips 集合中
        db.collection("trips").document("u9QgkOcQsZZh90D6SAfc").setData(tripData) { error in
            if let error = error {
                print("上传数据失败: \(error.localizedDescription)")
            } else {
                print("数据上传成功")
            }
        }
    }
    
}
