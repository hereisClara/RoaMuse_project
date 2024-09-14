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

class HomeViewController: UIViewController {
    
    private let locationManager = LocationManager()
    private let weatherManager = WeatherManager()
    
    private let dataManager = DataManager()
    
    private let randomTripEntryButton = UIButton(type: .system)
    
    private var randomTrip: Trip?
    
//    var onTripReceivedFromHome: ((Trip) -> Void)?
    
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
        
        locationManager.onLocationUpdate = { [weak self] location in
            self?.fetchWeather(for: location)
        }
        
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
        
//        print("======",dataManager.trips.randomElement())
//        randomTrip = dataManager.trips.randomElement()
        
//        指定奇險
        let filteredTrips = dataManager.trips.filter { $0.tag == 0 }
        guard let randomTrip = filteredTrips.randomElement() else { return }
        
//        隨機旅程
//        guard let randomTrip = dataManager.trips.randomElement() else { return }
        
        self.randomTrip = randomTrip

        
        PopUpView.shared.showPopup(on: self.view, with: randomTrip, and: dataManager.places)
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

