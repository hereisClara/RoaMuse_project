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
    private let dataManager = DataManager()
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
        dataManager.loadPlacesJSONData()
        getPlaceNameByPlaceId()
        setupUI()
        
    }
    
    func getPlaceNameByPlaceId() {
        
//        print(dataManager.places)
        
        guard let trip = trip else { return }
        
        for tripPlace in trip.places {
            
            for place in dataManager.places {
                
                if place.id == tripPlace {
                    
                    places.append(place)
                    placeName.append(place.name)
                    
                }
                
            }
            
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
            
            if canTapCompleteButton == true {
                completeButton.isEnabled = true
            } else {
                completeButton.isEnabled = false
            }
        }
        
    }
    
}
