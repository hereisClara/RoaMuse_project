//
//  TripDetailViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/14.
//

import Foundation
import UIKit
import CoreLocation
import SnapKit
import FirebaseFirestore

class TripDetailViewController: UIViewController {
    
    var trip: Trip?  // 存儲傳遞過來的資料
    var onTripReceivedFromHome: ((Trip) -> Void)?
    let placesStackView = UIStackView()
    private let locationManager = LocationManager()
    private var places = [Place]()
    private var placeName = [String]()
    let distanceThreshold: Double = 5000
    private var buttonState = [Bool]()
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        setupTableView()
        loadPlacesDataFromFirebase()
    }
    
    // 從 Firebase 加載 Places 資料
    func loadPlacesDataFromFirebase() {
        guard let trip = trip else { return }
        
        let placeIds = trip.places.map { $0.id }
        
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
            
            self.buttonState = Array(repeating: false, count: self.places.count)
            
            // 更新地點名稱
            self.placeName = self.places.map { $0.name }
            
            print("Updated placeName:", self.placeName)
            
            // 更新 UI，並且在加載完成後才開始設置 UI
            //                        self.setupUI()
            //            self.tableView.reloadData()
            
            DispatchQueue.main.async {
                print("Places data loaded, refreshing table view")
                self.tableView.reloadData() // 數據加載完成後刷新表格
            }
            // 啟動位置更新，並確保在 UI 設置完成後才計算距離
            self.locationManager.startUpdatingLocation()
            self.locationManager.onLocationUpdate = { [weak self] currentLocation in
                self?.checkDistances(from: currentLocation)
            }
        }
    }
    
    func checkDistances(from currentLocation: CLLocation) {
        
        print("開始計算距離")
        
        guard !places.isEmpty else {
            print("places 數組為空，無法計算距離")
            return
        }
        
        print("places 數組已加載，共 \(places.count) 個地點")
        
        for (index, place) in places.enumerated() {
            let targetLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = currentLocation.distance(from: targetLocation)
            print("距離 \(place.name): \(distance) 公尺")
            
            // 檢查是否有足夠的地點資料
            guard index < placeName.count else {
                print("placeName 陣列中沒有足夠的地點資料，無法檢查 index \(index)")
                continue // 如果 placeName 中沒有相應的地點，跳過這個迭代
            }
            
            if distance <= distanceThreshold {
                print("距離小於或等於 \(distanceThreshold) 公尺，地點 \(placeName[index]) 可用")
                buttonState[index] = true
                tableView.reloadData()
            } else {
                print("距離大於 \(distanceThreshold) 公尺，地點 \(placeName[index]) 不可用")
                buttonState[index] = false
            }
        }
    }
    
    
    
    func setupUI() {
        // 確保在主執行緒上更新 UI
        DispatchQueue.main.async {
            self.view.addSubview(self.placesStackView)
            
            self.placesStackView.snp.makeConstraints { make in
                make.center.equalTo(self.view)
                make.width.equalTo(self.view).multipliedBy(0.8)
            }
            
            self.placesStackView.axis = .vertical
            self.placesStackView.spacing = 30
            self.placesStackView.distribution = .fillProportionally
            
            guard let trip = self.trip else { return }
            
            for place in self.placeName {
                let placeLabel = UILabel()
                let completeButton = UIButton(type: .system)
                
                let horizontalStackView = UIStackView()
                horizontalStackView.axis = .horizontal
                horizontalStackView.spacing = 10
                horizontalStackView.distribution = .fillProportionally
                
                horizontalStackView.addArrangedSubview(placeLabel)
                horizontalStackView.addArrangedSubview(completeButton)
                
                self.placesStackView.addArrangedSubview(horizontalStackView)
                
                placeLabel.textColor = .black
                placeLabel.text = place
                
                completeButton.isEnabled = false
                completeButton.setTitle("完成", for: .normal)
                completeButton.setTitle("無法點選", for: .disabled)
                completeButton.setTitle("已完成", for: .selected)
                // 初始狀態設為不可用
                
                completeButton.addTarget(self, action: #selector(self.didTapCompleteButton(_:)), for: .touchUpInside)
            }
        }
    }
}

extension TripDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if placeName.isEmpty {
            print("placeName is empty, returning 0 rows") // 進一步檢查 placeName 是否為空
            return 0
        }
        return trip?.poem.original.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let poem = trip?.poem.original, !poem.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tripDetailCell", for: indexPath) as? TripDetailWithPlaceTableViewCell
            cell?.verseLabel.text = "詩句加載中"
            cell?.placeLabel.text = "地點數據加載中"
            return cell ?? UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripDetailCell", for: indexPath) as? TripDetailWithPlaceTableViewCell
        
        cell?.selectionStyle = .none
        
        if indexPath.row < poem.count {
            cell?.verseLabel.text = poem[indexPath.row]
        } else {
            cell?.verseLabel.text = "詩句加載中"
        }
        
        if indexPath.row % 2 == 0 {
            let dataIndex = indexPath.row / 2
            let isButtonEnabled = buttonState[dataIndex]
            if !placeName.isEmpty && dataIndex < placeName.count {
                cell?.placeLabel.text = placeName[dataIndex]
                cell?.completeButton.isHidden = false
                cell?.completeButton.isEnabled = isButtonEnabled
                cell?.completeButton.accessibilityIdentifier = places[dataIndex].id
                cell?.completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)
            } else {
                cell?.placeLabel.text = "無資料"
                cell?.completeButton.isHidden = true
                cell?.completeButton.isEnabled = isButtonEnabled
            }
        } else {
            cell?.placeLabel.text = nil // 對於其他行，你可以設定為 nil 或隱藏這個 label
            cell?.completeButton.isHidden = true
        }
        
        return cell ?? UITableViewCell()
        
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        
        // 設置 delegate 和 dataSource
        tableView.delegate = self
        tableView.dataSource = self
        
        // 註冊 cell
        tableView.register(TripDetailWithPlaceTableViewCell.self, forCellReuseIdentifier: "tripDetailCell")
        
        // 設置背景顏色為橘色
        tableView.backgroundColor = UIColor.orange
        
        // 使用 SnapKit 設置 tableView 的大小等於 safeArea
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    @objc func didTapCompleteButton(_ sender: UIButton) {
        guard let placeId = sender.accessibilityIdentifier else {
            print("無法獲取 placeId")
            return
        }

        // 更新本地 UI
        sender.isEnabled = false
        sender.isSelected = true

        // 獲取 tripId，假設 tripId 已經存在
        guard let trip = trip else {
            print("無法獲取 trip 資訊")
            return
        }
        let tripId = trip.id

        // 根據 placeId 找到對應的地點索引
        let placeIndex = places.firstIndex { $0.id == placeId }
        guard let dataIndex = placeIndex else {
            print("無法找到對應的地點")
            return
        }
        
        // 獲取當前地點資料，並更新 isComplete 狀態
        let currentPlace = places[dataIndex]
        let updatedPlace = [
            "id": currentPlace.id,
            "isComplete": true
        ] as [String: Any]
        
        // 更新 Firestore 中嵌套字段的 isComplete 狀態，並保持原有地點結構
        let placePath = "trips/\(tripId)"
        let db = Firestore.firestore()
        db.document(placePath).updateData([
            "places.\(dataIndex)": updatedPlace
        ]) { error in
            if let error = error {
                print("更新失敗: \(error)")
            } else {
                print("地點 \(placeId) 已完成")
                
                DispatchQueue.main.async {
                    self.tableView.reloadData() // 刷新表格
                }
            }
        }
    }


}
