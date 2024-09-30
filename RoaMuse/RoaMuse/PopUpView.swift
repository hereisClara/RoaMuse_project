//
//  PopUpView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore
import CoreLocation

protocol PopupViewDelegate: AnyObject {
    func navigateToTripDetailPage()
}

class PopUpView {
    
    weak var delegate: PopupViewDelegate?
    
    private var popupView = UIView()
    private var backgroundView = UIView()
    
    var tripId: String?
    
    let titleLabel = UILabel()
    let poetryLabel = UILabel()
    let tripStyleLabel = UILabel()
    
    let versesStackView = UIStackView()
    let placesStackView = UIStackView()
    let collectButton = UIButton()
    let startButton = UIButton()
    let cityLabel = UILabel()   // 用来显示城市
    let districtsStackView = UIStackView()
    
    var tapCollectButton: (() -> Void)?
    var onTripSelected: ((Trip) -> Void)?
    var fromEstablishToTripDetail: Trip?
    
    init() {}
    
    func showPopup(on view: UIView, with trip: Trip, city: String, districts: [String]) {
        
        guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else {
            return
        }
        self.tripId = trip.id
        checkIfTripBookmarked()
        
        fromEstablishToTripDetail = trip
        
        versesStackView.removeAllArrangedSubviews()
        placesStackView.removeAllArrangedSubviews()
        districtsStackView.removeAllArrangedSubviews()
        
        backgroundView.frame = window.bounds
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        window.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        backgroundView.addGestureRecognizer(tapGesture)
        
        popupView.backgroundColor = .deepBlue
        popupView.layer.cornerRadius = 10
        popupView.clipsToBounds = true
        window.addSubview(popupView)
        
        popupView.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.85)
            make.height.equalTo(600)
        }
        
        setupConstraints()
        
        FirebaseManager.shared.loadPoemById(trip.poemId) { [weak self] poem in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.titleLabel.text = poem.title
                self.poetryLabel.text = "\(poem.poetry)"
                self.tripStyleLabel.text = "\(styles[poem.tag].name)"
                
                self.versesStackView.removeAllArrangedSubviews()
                for verse in poem.content {
                    let verseLabel = UILabel()
                    verseLabel.text = verse
                    verseLabel.textColor = .white
                    self.versesStackView.addArrangedSubview(verseLabel)
                }
            }
        }
        
        FirebaseManager.shared.loadPlaces(placeIds: trip.placeIds) { [weak self] places in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.placesStackView.removeAllArrangedSubviews()
                for place in places {
                    let placeLabel = UILabel()
                    placeLabel.text = place.name
                    placeLabel.textColor = .white
                    self.placesStackView.addArrangedSubview(placeLabel)

                    // 進行反向編碼
                    let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
                    self.reverseGeocodeLocation(location) { city, district in
                        if let city = city, let district = district {
                            self.cityLabel.text = "城市: \(city)"
                            let districtLabel = UILabel()
                            districtLabel.text = "#\(district)"
                            districtLabel.textColor = .white
                            self.districtsStackView.addArrangedSubview(districtLabel)
                        }
                    }
                }
            }
        }
        
        backgroundView.alpha = 0
        popupView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = 1
            self.popupView.alpha = 1
        }
    }
    
    func setupConstraints() {
        
        popupView.addSubview(titleLabel)
        popupView.addSubview(poetryLabel)
        popupView.addSubview(tripStyleLabel)
        popupView.addSubview(versesStackView)
        popupView.addSubview(placesStackView)
        popupView.addSubview(collectButton)
        popupView.addSubview(startButton)
        popupView.addSubview(cityLabel)   // 添加城市标签
        popupView.addSubview(districtsStackView)
        
        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(placesStackView.snp.bottom).offset(30)
            make.centerX.equalTo(popupView)
        }
        
        districtsStackView.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(10)
            make.centerX.equalTo(popupView)
        }
        
        districtsStackView.spacing = 10
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(popupView).offset(40)
            make.centerX.equalTo(popupView)
        }
        
        poetryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalTo(popupView)
        }
        
        tripStyleLabel.snp.makeConstraints { make in
            make.top.equalTo(poetryLabel.snp.bottom).offset(10)
            make.centerX.equalTo(popupView)
        }
        
        versesStackView.snp.makeConstraints { make in
            make.top.equalTo(tripStyleLabel.snp.bottom).offset(30)
            make.centerX.equalTo(popupView)
        }
        
        versesStackView.axis = .vertical
        versesStackView.spacing = 10
        versesStackView.alignment = .center
        
        placesStackView.snp.makeConstraints { make in
            make.top.equalTo(versesStackView.snp.bottom).offset(30)
            make.centerX.equalTo(popupView)
        }
        
        placesStackView.axis = .vertical
        placesStackView.spacing = 10
        placesStackView.alignment = .center
        
        collectButton.snp.makeConstraints { make in
            make.bottom.equalTo(popupView).offset(-50)
            make.centerX.equalTo(popupView).offset(40)
            make.width.height.equalTo(30)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.equalTo(popupView).offset(-50)
            make.centerX.equalTo(popupView).offset(-40)
            make.width.height.equalTo(30)
        }
        
        titleLabel.textColor = .white
        poetryLabel.textColor = .white
        tripStyleLabel.textColor = .white
        
        // 設置按鈕圖標和顏色
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.tintColor = .white
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        
        collectButton.isEnabled = true
        collectButton.addTarget(self, action: #selector(didTapCollectButton), for: .touchUpInside)
        
        startButton.setImage(UIImage(systemName: "play"), for: .disabled)
        startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        startButton.tintColor = .white
        startButton.isEnabled = false
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
        
    }
    
    func checkIfTripBookmarked() {
            guard let userId = UserDefaults.standard.string(forKey: "userId"),
                  let tripId = tripId else {
                print("無法獲取 userId 或 tripId")
                return
            }

            let userRef = Firestore.firestore().collection("users").document(userId)
            
            userRef.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                if let document = document, document.exists {
                    DispatchQueue.main.async {
                        if let bookmarkTrips = document.data()?["bookmarkTrip"] as? [String] {
                            self.collectButton.isSelected = bookmarkTrips.contains(tripId)
                            // 更新按鈕顏色
                            self.collectButton.tintColor = self.collectButton.isSelected ? .accent : .white
                            self.startButton.isEnabled = self.collectButton.isSelected
                        }
                    }
                } else {
                    print("無法獲取用戶資料")
                }
            }
        }

    @objc func dismissPopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.popupView.alpha = 0
            self.backgroundView.alpha = 0
        }) { _ in
            // 完成動畫後移除 popupView 和 backgroundView
            self.popupView.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
        }
    }
    
    @objc func didTapStartButton() {
        
        popupView.removeFromSuperview()
        self.backgroundView.removeFromSuperview()
        
        if let fromEstablishToTripDetail = fromEstablishToTripDetail {
            onTripSelected?(fromEstablishToTripDetail)
        }
        
        delegate?.navigateToTripDetailPage()
    }
    
    @objc func didTapCollectButton() {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let tripId = tripId else {
            print("無法獲取 userId 或 tripId")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        if collectButton.isSelected {
            // 從 bookmarkTrip 中移除
            userRef.updateData([
                "bookmarkTrip": FieldValue.arrayRemove([tripId])
            ]) { error in
                if let error = error {
                    print("從 bookmarkTrip 中移除 tripId 時出錯: \(error.localizedDescription)")
                } else {
                    print("成功將 tripId 從 bookmarkTrip 中移除")
                }
            }
        } else {
            // 添加到 bookmarkTrip
            userRef.updateData([
                "bookmarkTrip": FieldValue.arrayUnion([tripId])
            ]) { error in
                if let error = error {
                    print("將 tripId 添加到 bookmarkTrip 中時出錯: \(error.localizedDescription)")
                } else {
                    print("成功將 tripId 添加到 bookmarkTrip 中")
                }
            }
        }
        
        collectButton.isSelected.toggle()
        collectButton.tintColor = collectButton.isSelected ? .accent : .white
        startButton.isEnabled = collectButton.isSelected
    }
    
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("反向地理編碼失敗: \(error.localizedDescription)")
                completion(nil, nil)
            } else if let placemark = placemarks?.first {
                let city = placemark.administrativeArea ?? "未知縣市"
                let district = placemark.locality ?? placemark.subLocality ?? "未知區"
                completion(city, district)
            } else {
                completion(nil, nil)
            }
        }
    }
}
