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
    
    var currentTargetIndex: Int = 0
    var loadedPoem: Poem?
    var trip: Trip?
    var onTripReceivedFromHome: ((Trip) -> Void)?
    let placesStackView = UIStackView()
    private let locationManager = LocationManager()
    private var places = [Place]()
    private var placeName = [String]()
    let distanceThreshold: Double = 15000
    private var buttonState = [Bool]()
    var selectedIndexPath: IndexPath?
    var completedPlaceIds: [String] = []
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        tabBarController?.tabBar.isHidden = false
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareButtonTapped))
        self.navigationItem.rightBarButtonItem = shareButton
        
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
        FirebaseManager.shared.fetchCompletedPlaces(userId: userId) { [weak self] completedPlaces in
            guard let self = self else { return }
            
            // 清空當前的 completedPlaceIds 列表
            self.completedPlaceIds = []
            
            // 遍歷 completedPlaces，找到符合當前行程 tripId 的 completedPlace
            for completedPlace in completedPlaces {
                if let tripId = completedPlace["tripId"] as? String,
                   let placeIds = completedPlace["placeIds"] as? [String],
                   tripId == self.trip?.id {
                    // 將符合條件的 placeIds 加入 completedPlaceIds 中
                    self.completedPlaceIds.append(contentsOf: placeIds)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        // 开始位置更新
        self.locationManager.startUpdatingLocation()
        self.locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            
            // 检查与当前目标地点的距离
            self.checkDistanceForCurrentTarget(from: currentLocation)
        }
    }
    
    @objc func shareButtonTapped() {
        let imageUploadVC = PhotoUploadViewController()
        self.navigationController?.pushViewController(imageUploadVC, animated: true)
    }
    
    func loadPoemDataFromFirebase() {
        
        self.loadedPoem = nil
        
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
        
        self.places.removeAll()
        
        guard let trip = trip else { return }
        
        let placeIds = trip.placeIds
        
        if placeIds.isEmpty {
            print("行程中無地點資料")
            return
        }
        
        FirebaseManager.shared.loadPlaces(placeIds: placeIds) { [weak self] (placesArray) in
            guard let self = self else { return }
            
            // 打印調試信息，檢查placesArray是否有正確加載
            print("placesArray loaded from Firebase: \(placesArray)")
            
            // 对 placesArray 进行排序
            self.places = trip.placeIds.compactMap { placeId in
                return placesArray.first(where: { $0.id == placeId })
            }
            
            // 打印已經排序後的 places
            print("Sorted places: \(self.places)")
            
            // 更新其他相关数据
            self.placeName = self.places.map { $0.name }
            
            DispatchQueue.main.async {
                // 初始化 buttonState
                if self.buttonState.count != self.places.count {
                    self.buttonState = Array(repeating: false, count: self.places.count)
                }
                self.tableView.reloadData()
                // 开始位置更新
                self.locationManager.startUpdatingLocation()
                self.locationManager.onLocationUpdate = { [weak self] currentLocation in
                    guard let self = self else { return }
                    self.checkDistanceForCurrentTarget(from: currentLocation)
                }
            }
            
            //            // 开始位置更新
            //            self.locationManager.startUpdatingLocation()
            //            self.locationManager.onLocationUpdate = { [weak self] currentLocation in
            //                self?.checkDistances(from: currentLocation)
            //            }
        }
        
    }
    
    func checkDistanceForCurrentTarget(from currentLocation: CLLocation) {
        guard currentTargetIndex < places.count else {
            print("所有地点都已完成")
            self.locationManager.stopUpdatingLocation()
            return
        }
        
        let place = places[currentTargetIndex]
        let targetLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
        let distance = currentLocation.distance(from: targetLocation)
        print("距离 \(place.name): \(distance) 米")
        
        if distance <= distanceThreshold {
            print("距离小于或等于 \(distanceThreshold) 米，地点 \(place.name) 可用")
            buttonState[currentTargetIndex] = true
            tableView.reloadRows(at: [IndexPath(row: currentTargetIndex, section: 0)], with: .none)
        } else {
            print("距离大于 \(distanceThreshold) 米，地点 \(place.name) 不可用")
            buttonState[currentTargetIndex] = false
            tableView.reloadRows(at: [IndexPath(row: currentTargetIndex, section: 0)], with: .none)
        }
    }
}

extension TripDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let poem = loadedPoem else {
            let headerView = UIView()
            headerView.backgroundColor = .deepBlue
            let label = UILabel()
            label.text = "詩句加載中"
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 24)
            headerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            return headerView
        }
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor(resource: .deepBlue)
        
        let titleLabel = UILabel()
        titleLabel.text = poem.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }
        
        // 詩人
        let poetLabel = UILabel()
        poetLabel.text = poem.poetry
        poetLabel.font = UIFont.systemFont(ofSize: 18)
        poetLabel.textAlignment = .center
        headerView.addSubview(poetLabel)
        poetLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
        }
        
        // 詩的內容
        let contentLabel = UILabel()
        contentLabel.text = poem.content.joined(separator: "\n")
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textAlignment = .center
        contentLabel.numberOfLines = 0
        headerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(poetLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        250
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return trip?.placeIds.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripDetailCell", for: indexPath) as? TripDetailWithPlaceTableViewCell
        cell?.selectionStyle = .none
        
        let dataIndex = indexPath.row
        
        if buttonState.count != places.count {
            buttonState = Array(repeating: false, count: places.count)
        }
        
        if !places.isEmpty && dataIndex < places.count {
            let isButtonEnabled = buttonState[dataIndex]
            let place = places[dataIndex]
            cell?.placeLabel.text = place.name
            cell?.completeButton.isHidden = false
            //            cell?.completeButton.isEnabled = isButtonEnabled
            
            // Remove existing targets to prevent multiple triggers
            cell?.completeButton.removeTarget(nil, action: nil, for: .allEvents)
            cell?.completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)
            
            cell?.completeButton.tag = indexPath.row
            cell?.completeButton.accessibilityIdentifier = place.id
            
            // Rest of your code...
            let isComplete = self.completedPlaceIds.contains(place.id)
            
            cell?.completeButton.isEnabled = (indexPath.row == currentTargetIndex) && buttonState[indexPath.row]
            
            cell?.completeButton.isSelected = isComplete
            cell?.completeButton.setTitle(isComplete ? "已完成" : "完成", for: .normal)
            cell?.moreInfoLabel.isHidden = !isComplete
        } else {
            cell?.placeLabel.text = "無資料"
            cell?.completeButton.isHidden = true
        }
        
        return cell ?? UITableViewCell()
    }
    
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(TripDetailWithPlaceTableViewCell.self, forCellReuseIdentifier: "tripDetailCell")
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    @objc func didTapCompleteButton(_ sender: UIButton) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let placeId = sender.accessibilityIdentifier else {
            return
        }
        guard let trip = trip else {
            return
        }
        
        let index = sender.tag
        
        // 确保只有当前目标地点的按钮可以点击
        guard index == currentTargetIndex else {
            return
        }
        
        let tripId = trip.id
        
        // 更新 Firebase 数据
        FirebaseManager.shared.updateCompletedTripAndPlaces(for: userId, trip: trip, placeId: placeId) { success in
            if success {
                print("地点 \(placeId) 和行程 \(tripId) 成功更新")
                
                DispatchQueue.main.async {
                    sender.isSelected = true
                    sender.isEnabled = false
                    self.completedPlaceIds.append(placeId)
                    self.buttonState[self.currentTargetIndex] = false // 禁用已完成地点的按钮
                    self.currentTargetIndex += 1
                    // 更新下一目标地点的按钮状态
                    self.tableView.reloadData()
                }
            } else {
                print("更新失败")
            }
        }
    }
}
