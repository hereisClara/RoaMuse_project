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
    
    let startButton = UIButton()
    let cityLabel = UILabel()   // 用来显示城市
    let districtsStackView = UIStackView()
    
    var tapCollectButton: (() -> Void)?
    var onTripSelected: ((Trip) -> Void)?
    var fromEstablishToTripDetail: Trip?
    let matchingScoreLabel = UILabel()
    
    init() {}
    
    func showPopup(on view: UIView, with trip: Trip, city: String, districts: [String], matchingScore: Double? = nil) {
        
        guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else {
            return
        }
        
        if let matchingScore = matchingScore {
            matchingScoreLabel.text = "\(matchingScore)% 匹配"
            matchingScoreLabel.isHidden = false
        } else {
            matchingScoreLabel.isHidden = true
        }
        
        self.tripId = trip.id
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
            backgroundView.addSubview(popupView)

            popupView.snp.makeConstraints { make in
                make.center.equalTo(backgroundView)
                make.width.equalTo(backgroundView).multipliedBy(0.88)
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
                    verseLabel.textColor = .accent
                    verseLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
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
                    placeLabel.textColor = .backgroundGray
                    placeLabel.font = UIFont(name: "NotoSerifHK-Black", size: 18)
                    self.placesStackView.addArrangedSubview(placeLabel)

                    // 進行反向編碼
                    let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
                    self.reverseGeocodeLocation(location) { city, district in
                        if let city = city, let district = district {
                            self.cityLabel.text = "\(city)"
                            self.cityLabel.font = UIFont(name: "NotoSerifHK-Black", size: 18)
                            self.cityLabel.textColor = .backgroundGray
                            let districtLabel = UILabel()
                            districtLabel.text = "#\(district)"
                            districtLabel.textColor = .backgroundGray
                            districtLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)

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
        
        popupView.addSubview(startButton)
        popupView.addSubview(cityLabel)   // 添加城市标签
        popupView.addSubview(districtsStackView)
        popupView.addSubview(matchingScoreLabel)
        
        matchingScoreLabel.snp.makeConstraints { make in
            make.trailing.equalTo(popupView).offset(-20)
            make.bottom.equalTo(popupView).offset(-60)
            make.width.equalTo(160)  // 設置寬度
            make.height.equalTo(60)  // 設置高度
        }
        
        matchingScoreLabel.textColor = .accent
        matchingScoreLabel.textAlignment = .center
        matchingScoreLabel.layer.masksToBounds = true
        
        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(placesStackView.snp.bottom).offset(30)
            make.leading.equalTo(titleLabel)
        }
        
        districtsStackView.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
        
        districtsStackView.spacing = 8
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(popupView).offset(40)
            make.leading.equalTo(popupView).offset(20)
        }
        
        poetryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
        
        tripStyleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(poetryLabel.snp.bottom)
            make.leading.equalTo(poetryLabel.snp.trailing).offset(12)
        }
        
        versesStackView.snp.makeConstraints { make in
            make.top.equalTo(tripStyleLabel.snp.bottom).offset(30)
            make.leading.equalTo(titleLabel)
        }
        
        versesStackView.axis = .vertical
        versesStackView.spacing = 10
        versesStackView.alignment = .leading
        
        placesStackView.snp.makeConstraints { make in
            make.top.equalTo(versesStackView.snp.bottom).offset(30)
            make.leading.equalTo(titleLabel)
        }
        
        placesStackView.axis = .vertical
        placesStackView.spacing = 10
        placesStackView.alignment = .leading
        
        startButton.snp.makeConstraints { make in
            make.bottom.equalTo(popupView).offset(-20)
            make.trailing.equalTo(popupView).offset(-20)
            make.width.height.equalTo(45)
        }
        
        titleLabel.textColor = .accent
        poetryLabel.textColor = .backgroundGray
        tripStyleLabel.textColor = .backgroundGray
        cityLabel.textColor = .backgroundGray
        
//        startButton.setImage(UIImage(systemName: "play"), for: .disabled)
        startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        startButton.tintColor = .accent
        startButton.isEnabled = true
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
        
        setupLabel()
    }
    
    func setupLabel() {
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 40)
        poetryLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 22)
        tripStyleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        matchingScoreLabel.font = UIFont(name: "NotoSerifHK-Black", size: 26)
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
            // 移除popup视图
            popupView.removeFromSuperview()
            backgroundView.removeFromSuperview()
            
            if let tripId = tripId {
                guard let userId = UserDefaults.standard.string(forKey: "userId") else {
                    print("無法獲取 userId 或 tripId")
                    return
                }
                
                let userRef = Firestore.firestore().collection("users").document(userId)
                
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
            
            // 執行原有的功能
            if let fromEstablishToTripDetail = fromEstablishToTripDetail {
                onTripSelected?(fromEstablishToTripDetail)
            }
            
            delegate?.navigateToTripDetailPage()
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
