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

class HomeViewController: UIViewController {
    
    private let locationManager = LocationManager()
    private let weatherManager = WeatherManager()
    
    private let dataManager = DataManager()
    
    private let randomTripEntryButton = UIButton(type: .system)
    
    private var randomTrip: Trip?
    
//    var isPopupVisible = false // 用來記錄彈出視窗的狀態
//    var popupTripData: Trip?   // 用來保存彈窗的資料
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "首頁"
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        PopUpView.shared.delegate = self
        
        dataManager.loadJSONData()
        dataManager.loadPlacesJSONData()
        
        setupRandomTripEntryUI()
        
//        locationManager.onLocationUpdate = { [weak self] location in
//            self?.fetchWeather(for: location)
//        }
        
//        locationManager.onLocationUpdate = { [weak self] currentLocation in
//            guard let self = self else { return }
//            
//            // 假設你的目標地點是台北101
//            let targetLocation = CLLocation(latitude: 25.033964, longitude: 121.564468)
//            
//            // 計算距離
//            let distance = currentLocation.distance(from: targetLocation)
//            print("距離台北101: \(distance) 公尺")
//        }
        
    }
    
    func setupRandomTripEntryUI() {
        
        view.addSubview(randomTripEntryButton)
        
        randomTripEntryButton.snp.makeConstraints { make in
            make.width.height.equalTo(80)
            make.center.equalTo(view)
        }
        
        randomTripEntryButton.backgroundColor = .lightGray
        
        randomTripEntryButton.addTarget(self, action: #selector(randomTripEntryButtonDidTapped), for: .touchUpInside)
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
            
            self?.updateUserCollections(userId: "qluFSSg8P1fGmWfXjOx6", tripId: randomTrip.id)
            
        }
    }
    
    func updateUserCollections(userId: String, tripId: String) {
        // 獲取 Firestore 的引用
        let db = Firestore.firestore()
        
        // 指定用戶文檔的路徑
        let userRef = db.collection("users").document(userId)
        
        // 使用 `updateData` 方法只更新 followersCount 字段
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // 如果文檔存在，則更新收藏
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
                // 如果文檔不存在，提示錯誤或創建新文檔
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

