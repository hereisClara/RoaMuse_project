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
    var selectedIndexPath: IndexPath?
    var completedPlaceIds: [String] = []
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        if let trip = trip {
                print("成功接收到行程數據: \(trip)")
            } else {
                print("未接收到行程數據")
            }
        
        setupTableView()
        loadPlacesDataFromFirebase()
        FirebaseManager.shared.fetchCompletedPlaces(userId: userId) { [weak self] placeIds in
            self?.completedPlaceIds = placeIds
            print("獲取的 completedPlaceIds: \(self?.completedPlaceIds)")
            self?.tableView.reloadData()
        }
    }
    
    func loadPlacesDataFromFirebase() {
        guard let trip = trip else { return }
        
        let placeIds = trip.places.map { $0.id }
        
        if placeIds.isEmpty {
            print("行程中無地點資料")
            return
        }
        
        FirebaseManager.shared.loadPlaces(placeIds: placeIds) { [weak self] (placesArray) in
            guard let self = self else { return }
            
            // 檢查是否有資料
            if placesArray.isEmpty {
                print("無法加載地點詳細資料")
                return
            }
            
            // 重新根據 placeIds 的順序排列 placesArray
            let sortedPlaces = placeIds.compactMap { placeId in
                placesArray.first(where: { $0.id == placeId })
            }
            
            // 檢查是否成功排序
            if sortedPlaces.count != placeIds.count {
                print("加載地點時發生錯誤，地點數量不匹配")
                return
            }

            // 將資料存儲在 places 陣列中
            self.places = sortedPlaces
            
            self.buttonState = Array(repeating: false, count: self.places.count)
            
            // 更新地點名稱
            self.placeName = self.places.map { $0.name }
            
            print("Updated placeName:", self.placeName)
            
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
}

extension TripDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
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
                
                if selectedIndexPath == indexPath {
                    cell?.moreInfoLabel.isHidden = false
                    cell?.moreInfoLabel.text = trip?.poem.secretTexts[dataIndex]
                } else {
                    cell?.moreInfoLabel.isHidden = true
                }
                
                let placeId = places[dataIndex].id
                
                // 根據 Firebase 中的 isComplete 狀態設置按鈕選中狀態
                let isComplete = completedPlaceIds.contains(placeId)
                
                // 根據 isComplete 設置按鈕和狀態
                if isComplete {
                    cell?.completeButton.isSelected = true
                    cell?.completeButton.setTitle("已完成", for: .selected)
                    cell?.moreInfoLabel.isHidden = false
                    cell?.moreInfoLabel.text = trip?.poem.secretTexts[dataIndex]
                } else {
                    print("未包含")
                    cell?.completeButton.isSelected = false
                    cell?.completeButton.setTitle("完成", for: .normal)
                    cell?.moreInfoLabel.isHidden = true
                }
                
                if cell?.completeButton.isSelected == true {
                    cell?.moreInfoLabel.isHidden = false
                    cell?.moreInfoLabel.text = trip?.poem.secretTexts[dataIndex]
                } else {
                    cell?.moreInfoLabel.isHidden = true
                }
                
                cell?.completeButton.setTitle(isButtonEnabled ? "完成" : "無法點選", for: .normal)
                cell?.completeButton.setTitle("已完成", for: .selected)
            } else {
                cell?.placeLabel.text = "無資料"
                cell?.completeButton.isHidden = true
                cell?.completeButton.isEnabled = isButtonEnabled
            }
        } else {
            let dataIndex = (indexPath.row - 1) / 2
            
            if let situationTexts = trip?.poem.situationText, dataIndex < situationTexts.count {
                cell?.moreInfoLabel.text = situationTexts[dataIndex]
                cell?.moreInfoLabel.isHidden = false
            } else {
                cell?.moreInfoLabel.text = nil
                cell?.moreInfoLabel.isHidden = true
            }
            
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
        
        sender.isSelected = true
        sender.isEnabled = false

        let point = sender.convert(CGPoint.zero, to: tableView)

        if let indexPath = tableView.indexPathForRow(at: point) {
            guard let trip = trip else {
                print("無法獲取行程資訊")
                return
            }

            let placeIndex = indexPath.row / 2
            guard placeIndex < trip.places.count else {
                print("地點索引超出範圍")
                return
            }

            let placeId = trip.places[placeIndex].id
            let tripId = trip.id

            // 將地點和行程的資訊上傳到 users.completedPlace 和 completedTrip
            FirebaseManager.shared.updateCompletedTripAndPlaces(for: userId, trip: trip, placeId: placeId) { success in
                if success {
                    print("地點 \(placeId) 和行程 \(tripId) 成功更新")

                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                } else {
                    print("更新失敗")
                }
            }
        }
    }
}
