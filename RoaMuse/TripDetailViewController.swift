//
//  TripDetailViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/14.
//

import Foundation
import UIKit
import CoreLocation

class TripDetailViewController: UIViewController {
    
    var trip: Trip?  // 存儲傳遞過來的資料
    var onTripReceivedFromHome: ((Trip) -> Void)?
    let placesStackView = UIStackView()
    private let locationManager = LocationManager()
    private var places = [Place]()
    private var placeName = [String]()
    let distanceThreshold: Double = 3600
    var canTapCompleteButton: Bool? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.startUpdatingLocation()
        locationManager.onLocationUpdate = { [weak self] currentLocation in
            self?.checkDistances(from: currentLocation)
        }
        view.backgroundColor = UIColor(resource: .backgroundGray)
        setupUI()
        loadPlacesDataFromFirebase() // 從 Firebase 獲取 Places 資料
    }
    
    // 從 Firebase 加載 Places 資料
    func loadPlacesDataFromFirebase() {
        guard let trip = trip else { return }
        
        // 獲取該行程中的所有 place ID
        let placeIds = trip.places.map { $0.id }
        
        // 使用 FirebaseManager 從 Firebase 加載 places 資料
        FirebaseManager.shared.loadPlaces(placeIds: placeIds) { [weak self] (placesArray) in
            guard let self = self else { return }
            self.places = placesArray.compactMap { data in
                if let id = data.id as? String,
                   let name = data.name as? String,
                   let latitude = data.latitude as? Double,
                   let longitude = data.longitude as? Double {
                    return Place(id: id, name: name, latitude: latitude, longitude: longitude)
                }
                return nil
            }
            
            // 更新地點名稱
            self.placeName = self.places.map { $0.name }
            
            // 更新 UI
            self.setupUI()
        }
    }
    
    func checkDistances(from currentLocation: CLLocation) {
        for (index, place) in places.enumerated() {
            let targetLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = currentLocation.distance(from: targetLocation)
            print("距離 \(place.name): \(distance) 公尺")
            
            // 獲取對應的 completeButton 並根據距離設置狀態
            if let horizontalStackView = placesStackView.arrangedSubviews[index] as? UIStackView,
               let completeButton = horizontalStackView.arrangedSubviews.last as? UIButton {
                if distance <= distanceThreshold {
                    print("距離小於或等於 \(distanceThreshold) 公尺，按鈕可用")
                    completeButton.isEnabled = true
                } else {
                    print("距離大於 \(distanceThreshold) 公尺，按鈕不可用")
                    completeButton.isEnabled = false
                }
            }
        }
    }

    func setupUI() {
        view.addSubview(placesStackView)
        
        placesStackView.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.8)
        }
        
        placesStackView.axis = .vertical
        placesStackView.spacing = 30
        placesStackView.distribution = .fillProportionally
        
        guard let trip = trip else { return }
        
        for place in placeName {
            let placeLabel = UILabel()
            let completeButton = UIButton(type: .system)
            
            let horizontalStackView = UIStackView()
            horizontalStackView.axis = .horizontal
            horizontalStackView.spacing = 10
            horizontalStackView.distribution = .fillProportionally
            
            horizontalStackView.addArrangedSubview(placeLabel)
            horizontalStackView.addArrangedSubview(completeButton)
            
            placesStackView.addArrangedSubview(horizontalStackView)
            
            placeLabel.textColor = .black
            placeLabel.text = place
            
            completeButton.setTitle("完成", for: .normal)
            completeButton.setTitle("無法點選", for: .disabled)
            completeButton.isEnabled = false // 初始狀態設為不可用
            
            completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)
        }
    }
    
    @objc func didTapCompleteButton(_ sender: UIButton) {
        sender.isEnabled = false
        // 處理按鈕點擊事件
        // 更新 Firebase 上的行程狀態
    }
}
