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
    
    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        uploadPlaces()
        self.title = "首頁"
        view.backgroundColor = UIColor(resource: .backgroundGray)
        homeTableView.register(PostsTableViewCell.self, forCellReuseIdentifier: "postCell")
        PopUpView.shared.delegate = self
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        
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
                    PopUpView.shared.showPopup(on: self.view, with: randomTrip)
                    
                    PopUpView.shared.tapCollectButton = { [weak self] in
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
    
    @objc func didTapCollectButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        // 獲取按鈕點擊所在的行
        let point = sender.convert(CGPoint.zero, to: homeTableView)
        
        if let indexPath = homeTableView.indexPathForRow(at: point) {
            let postData = postsArray[indexPath.row]
            let postId = postData["id"] as? String ?? ""
            let userId = "Am5Jsa1tA0IpyXMLuilm" // 假設為當前使用者ID
            
            if sender.isSelected {
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        print("收藏成功")
                    } else {
                        print("收藏失敗")
                    }
                }
            } else {
                FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                    if success {
                        print("取消收藏成功")
                    } else {
                        print("取消收藏失敗")
                    }
                }
            }
        }
    }
    
    func uploadPlaces() {
        let db = Firestore.firestore()
        
        let places: [[String: Any]] = [
            [
                "name": "富陽自然生態公園",
                "latitude": 25.016924346039385,
                "longitude": 121.55755193966566
            ],
            [
                "name": "四四南村",
                "latitude": 25.031642589075492,
                "longitude": 121.56188059548683
            ],
            [
                "name": "碧潭吊橋",
                "latitude": 24.957199843183766,
                "longitude": 121.53564486496339
            ],
            [
                "name": "台北101觀景台",
                "latitude": 25.03392792253846,
                "longitude": 121.56477580712797
            ],
            [
                "name": "清天宮(面天山)登山口",
                "latitude": 25.160252449667908,
                "longitude": 121.50166513466553
            ],
            [
                "name": "淡水漁人碼頭",
                "latitude": 25.183565593165902,
                "longitude": 121.41131772210223
            ]
        ]
        
        for place in places {
            // 为每个文档创建新的 ID
            let newDocument = db.collection("places").document()
            var placeWithId = place
            
            // 使用 documentId 作为 place 的 id 字段
            placeWithId["id"] = newDocument.documentID
            
            // 上传数据
            newDocument.setData(placeWithId) { error in
                if let error = error {
                    print("Error adding place with ID \(newDocument.documentID): \(error)")
                } else {
                    print("Place with ID \(newDocument.documentID) added successfully!")
                }
            }
        }
    }
}
