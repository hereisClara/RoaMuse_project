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
    let cityLabel = UILabel()
    let districtsStackView = UIStackView()
    
    var tapCollectButton: (() -> Void)?
    var onTripSelected: ((Trip) -> Void)?
    var fromEstablishToTripDetail: Trip?
    let matchingScoreLabel = UILabel()
    
    init() {}
    
    func showPopup(on view: UIView, with trip: Trip, city: String?, districts: [String]?, matchingScore: Double? = nil) {
        
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
                self.tripStyleLabel.text = "\(styles[poem.tag + 1].name)"
                
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
        popupView.addSubview(cityLabel)
        popupView.addSubview(districtsStackView)
        popupView.addSubview(matchingScoreLabel)
        
        matchingScoreLabel.snp.makeConstraints { make in
            make.trailing.equalTo(popupView).offset(-20)
            make.bottom.equalTo(popupView).offset(-60)
            make.width.equalTo(160)
            make.height.equalTo(60) 
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
            make.trailing.equalTo(popupView).offset(-20)
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
        
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .accent
        poetryLabel.textColor = .backgroundGray
        tripStyleLabel.textColor = .backgroundGray
        cityLabel.textColor = .backgroundGray
        
        startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        startButton.tintColor = .accent
        startButton.isEnabled = true
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
        
        setupLabel()
    }
    
    func setupLabel() {
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 36)
        poetryLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 22)
        tripStyleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        matchingScoreLabel.font = UIFont(name: "NotoSerifHK-Black", size: 26)
    }

    @objc func dismissPopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.popupView.alpha = 0
            self.backgroundView.alpha = 0
        }) { _ in
            self.popupView.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
        }
    }
    
    @objc func didTapStartButton() {
        guard let tripId = tripId, let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId 或 tripId")
            return
        }

        fetchPoemId(for: tripId) { [weak self] currentPoemId in
            guard let self = self, let currentPoemId = currentPoemId else { return }

            self.fetchUserBookmarks(userId: userId) { bookmarkedTripIds in
                self.checkForDuplicatePoemId(bookmarkedTripIds: bookmarkedTripIds, currentPoemId: currentPoemId) { duplicateExists, duplicateTripId in
                    if duplicateExists, let duplicateTripId = duplicateTripId {
                        self.showOverrideAlert(for: tripId, userId: userId, duplicateTripId: duplicateTripId)
                    } else {
                        self.addTripToBookmark(tripId: tripId, userId: userId)
                    }
                }
            }
        }
    }

    private func fetchPoemId(for tripId: String, completion: @escaping (String?) -> Void) {
        let tripRef = Firestore.firestore().collection("trips").document(tripId)

        tripRef.getDocument { document, error in
            if let error = error {
                print("獲取 trip 資料失敗: \(error.localizedDescription)")
                completion(nil)
                return
            }

            let poemId = document?.data()?["poemId"] as? String
            completion(poemId)
        }
    }

    private func fetchUserBookmarks(userId: String, completion: @escaping ([String]) -> Void) {
        let userRef = Firestore.firestore().collection("users").document(userId)

        userRef.getDocument { document, error in
            if let error = error {
                print("獲取 user 資料失敗: \(error.localizedDescription)")
                completion([])
                return
            }

            let bookmarkedTripIds = document?.data()?["bookmarkTrip"] as? [String] ?? []
            completion(bookmarkedTripIds)
        }
    }

    private func checkForDuplicatePoemId(bookmarkedTripIds: [String], currentPoemId: String, completion: @escaping (Bool, String?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var duplicateTripId: String?
        var duplicateExists = false

        for tripId in bookmarkedTripIds {
            dispatchGroup.enter()
            
            fetchPoemId(for: tripId) { poemId in
                if poemId == currentPoemId {
                    duplicateExists = true
                    duplicateTripId = tripId
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(duplicateExists, duplicateTripId)
        }
    }

    private func showOverrideAlert(for tripId: String, userId: String, duplicateTripId: String) {
        let alert = UIAlertController(title: "覆蓋收藏", message: "此詩已在您的收藏中，是否覆蓋？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "覆蓋", style: .destructive) { [weak self] _ in
            self?.replaceTripInBookmark(newTripId: tripId, oldTripId: duplicateTripId, userId: userId)
        })
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func replaceTripInBookmark(newTripId: String, oldTripId: String, userId: String) {
        let userRef = Firestore.firestore().collection("users").document(userId)

        userRef.updateData([
            "bookmarkTrip": FieldValue.arrayRemove([oldTripId])
        ]) { [weak self] error in
            if let error = error {
                print("移除舊 tripId 失敗: \(error.localizedDescription)")
            } else {
                print("成功移除舊 tripId")
                self?.addTripToBookmark(tripId: newTripId, userId: userId)
            }
        }
    }

    private func addTripToBookmark(tripId: String, userId: String) {
        let userRef = Firestore.firestore().collection("users").document(userId)

        userRef.updateData([
            "bookmarkTrip": FieldValue.arrayUnion([tripId])
        ]) { [weak self] error in
            if let error = error {
                print("添加 trip 到 bookmark 失敗: \(error.localizedDescription)")
            } else {
                print("成功添加 trip 到 bookmark")
                self?.dismissPopupAndNavigateToDetail()
            }
        }
    }

    @objc func dismissPopupAndNavigateToDetail() {
        UIView.animate(withDuration: 0.3, animations: {
            self.popupView.alpha = 0
            self.backgroundView.alpha = 0
        }) { [weak self] _ in
            self?.popupView.removeFromSuperview()
            self?.backgroundView.removeFromSuperview()
            
            self?.delegate?.navigateToTripDetailPage()
        }
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
