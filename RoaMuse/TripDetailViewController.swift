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
    
    var loadedPoem: Poem?  // 加載到的詩詞資料
//    var places = [Place]()  // 加載到的地點資料
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
        self.navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        if let poemId = trip?.poemId {
            FirebaseManager.shared.loadPoemById(poemId) { [weak self] poem in
                guard let self = self else { return }
                // 獲取到的 poem 可以存到變數中供後續使用
                self.updatePoemData(poem: poem)
            }
        }

        if let trip = trip {
            print("成功接收到行程數據: \(trip)")
        } else {
            print("未接收到行程數據")
        }

        setupTableView()
        loadPlacesDataFromFirebase()
        loadPoemDataFromFirebase()
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        FirebaseManager.shared.fetchCompletedPlaces(userId: userId) { [weak self] placeIds in
            self?.completedPlaceIds = placeIds
            print("獲取的 completedPlaceIds: \(self?.completedPlaceIds)")
            self?.tableView.reloadData()
        }
    }
    
    func loadPoemDataFromFirebase() {
        guard let trip = trip else { return }
        
        // 使用 trip.poemId 來加載詩詞
        FirebaseManager.shared.loadPoemById(trip.poemId) { [weak self] poem in
            guard let self = self else { return }
            
            // 儲存加載到的詩詞資料
            self.loadedPoem = poem
            
            // 更新界面
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func updatePoemData(poem: Poem) {
        // 更新您的 UI，例如 tableView 重新加載資料
        self.tableView.reloadData()
    }

    
    func loadPlacesDataFromFirebase() {
        guard let trip = trip else { return }
        
        let placeIds = trip.placeIds
        
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
        guard let poem = loadedPoem else {
            // 如果 `Poem` 尚未加載，返回 0
            return 0
        }
        
        // 返回 `Poem` 中 `content` 的行數
        return poem.content.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripDetailCell", for: indexPath) as? TripDetailWithPlaceTableViewCell
        cell?.selectionStyle = .none

        // 確保已加載詩詞資料
        guard let poem = self.loadedPoem else {
            cell?.verseLabel.text = "詩句加載中"
            cell?.placeLabel.text = "地點數據加載中"
            return cell ?? UITableViewCell()
        }
        
        // 顯示詩詞內容
        if indexPath.row < poem.content.count {
            cell?.verseLabel.text = poem.content[indexPath.row]
        } else {
            cell?.verseLabel.text = "詩句加載中"
        }

        // 如果是地點的行
        if indexPath.row % 2 == 0 {
            let dataIndex = indexPath.row / 2
            let isButtonEnabled = buttonState[dataIndex]
            
            // 確保已加載地點資料
            if !places.isEmpty && dataIndex < places.count {
                let place = places[dataIndex]
                cell?.placeLabel.text = place.name
                cell?.completeButton.isHidden = false
                cell?.completeButton.isEnabled = isButtonEnabled
                cell?.completeButton.accessibilityIdentifier = place.id
                cell?.completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)

                let placeId = place.id

                // 檢查地點是否已完成
                let isComplete = completedPlaceIds.contains(placeId)
                cell?.completeButton.isSelected = isComplete
                cell?.completeButton.setTitle(isComplete ? "已完成" : "完成", for: .normal)

                // 顯示更多資訊
                if isComplete {
                    cell?.moreInfoLabel.isHidden = false
//                    cell?.moreInfoLabel.text = poem.secretTexts[dataIndex]
                } else {
                    cell?.moreInfoLabel.isHidden = true
                }

            } else {
                cell?.placeLabel.text = "無資料"
                cell?.completeButton.isHidden = true
            }
        } else {
            let dataIndex = (indexPath.row - 1) / 2
            
            // 顯示情境描述
//            if dataIndex < poem.situationText.count {
////                cell?.moreInfoLabel.text = poem.situationText[dataIndex]
//                cell?.moreInfoLabel.isHidden = false
//            } else {
//                cell?.moreInfoLabel.isHidden = true
//            }

            cell?.placeLabel.text = nil
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
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

        sender.isSelected = true
        sender.isEnabled = false

        let point = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            guard let trip = trip else {
                print("無法獲取行程資訊")
                return
            }

            let placeIndex = indexPath.row / 2
            guard placeIndex < trip.placeIds.count else {
                print("地點索引超出範圍")
                return
            }

            let placeId = trip.placeIds[placeIndex]

            let tripId = trip.id

            // 更新 Firebase 資料
            FirebaseManager.shared.updateCompletedTripAndPlaces(for: userId, trip: trip, placeId: placeId) { success in
                if success {
                    print("地點 \(placeId) 和行程 \(tripId) 成功更新")
                    
                    // 在資料庫更新成功後，仍然保留 UI 已更新的狀態
                    DispatchQueue.main.async {
                        self.completedPlaceIds.append(placeId)
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                } else {
                    print("更新失敗")
                    DispatchQueue.main.async {
                        // 如果更新失敗，將按鈕恢復為未完成狀態
                        sender.isSelected = false
                        sender.isEnabled = true
                    }
                }
            }
        }
    }
}
