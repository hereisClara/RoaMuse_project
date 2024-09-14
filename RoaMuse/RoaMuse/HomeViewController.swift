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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
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
        
//        指定浪漫派
        let filteredTrips = dataManager.trips.filter { $0.tag == 0 }
        
        guard let randomTrip = filteredTrips.randomElement() else { return }
        
        PopUpView.shared.showPopup(on: self.view, with: randomTrip)
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

