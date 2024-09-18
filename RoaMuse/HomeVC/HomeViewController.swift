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
    
    private let dataManager = DataManager()
    
    private let randomTripEntryButton = UIButton(type: .system)
    private let recommendRandomTripView = UIView()
    private let homeTableView = UITableView()
    
    private var randomTrip: Trip?
    
    var postsArray = [[String: Any]]()
    
//    var isPopupVisible = false // 用來記錄彈出視窗的狀態
//    var popupTripData: Trip?   // 用來保存彈窗的資料
    
    override func viewDidLoad() {
        super.viewDidLoad()
        test()
        self.title = "首頁"
        view.backgroundColor = UIColor(resource: .backgroundGray)
        homeTableView.register(PostsTableViewCell.self, forCellReuseIdentifier: "postCell")
        PopUpView.shared.delegate = self
        
        dataManager.loadJSONData()
        dataManager.loadPlacesJSONData()
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        
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
        //        TODO: 判斷季節，並按照指定季節篩選行程
        
//        指定奇險
        let filteredTrips = dataManager.trips.filter { $0.tag == 0 }
        guard let randomTrip = filteredTrips.randomElement() else { return }
        
//        隨機旅程
//        guard let randomTrip = dataManager.trips.randomElement() else { return }
        
        self.randomTrip = randomTrip

        PopUpView.shared.showPopup(on: self.view, with: randomTrip, and: dataManager.places)
        
        PopUpView.shared.tapCollectButton = { [weak self] in
            self?.updateUserCollections(userId: "Am5Jsa1tA0IpyXMLuilm", tripId: randomTrip.id)
        }
    }
    
    func updateUserCollections(userId: String, tripId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                userRef.updateData([
                    "bookmarkTrip": FieldValue.arrayUnion([self.randomTrip?.id])
                ]) { error in
                    if let error = error {
                        print("更新收藏旅程失敗：\(error.localizedDescription)")
                    } else {
                        print("收藏旅程更新成功！")
                    }
                }
            } else {
                
                print("文檔不存在，無法更新")
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
        150
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postsArray.count
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
                // 收藏文章
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        print("收藏成功")
                    } else {
                        print("收藏失敗")
                    }
                }

            } else {
                // 取消收藏
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
    
    func test() {
        
        let db = Firestore.firestore()
        let trips = Firestore.firestore().collection("trips")
        let document = trips.document()
        let tripData: [String: Any] = [
            "poem": [
                        "title": "〈夜宿山寺〉",
                        "poetry": "李白",
                        "original": [
                            "危樓高百尺，手可摘星辰。",
                            "不敢高聲語，恐驚天上人。"
                        ],
                        "translation": [
                            "山上寺院的高樓真高啊，好像有一百尺的樣子，人在樓上好像一伸手就可以摘下天上的星星。",
                            "站在這裡，我不敢大聲說話，唯恐驚動天上的神仙。"
                        ],
                        "secretTexts": [
                            "李白自號「青蓮居士」，源於《維摩詰經》的「青蓮」，展現他對佛教的崇敬和對維摩詘生活方式的嚮往。他不僅在詩中多次引用「青蓮」，還將維摩詘視為自己的精神榜樣，特別推崇《維摩詰經》中的「入諸酒肆，能立其志」的教義。"
                        ],
                        "situationText": [
                            "台北101的觀景台是城市中最高的地方，從這裡俯瞰整個台北，感受到與天空接近的高度。站在這樣的高處，彷彿一個輕聲細語就能驚擾天上的人，體會詩中的敬畏與謙卑之感。"
                        ]
                    ],
                    "id": document.documentID,gi
                    "places": [
                        ["id": "004", "isComplete": false]
                    ],
                    "tag": 1,
                    "season": 4,
                    "weather": 2,
                    "startTime": 2,
                    "isComplete": false
                ]

        // 將資料寫入 Firestore
        db.collection("trips").addDocument(data: tripData) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added successfully!")
            }
        }
    
        
        
    }
}
