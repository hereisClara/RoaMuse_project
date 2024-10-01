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
import MapKit
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
    
    var tableView = UITableView()
    
    let progressView = UIView() // The vertical progress view container
    let progressBar = UIProgressView(progressViewStyle: .bar) // The actual progress bar
    var progressDots = [UIView]()
    
    var totalTravelTime: TimeInterval? // 用來存儲總交通時間
    var routesArray: [[MKRoute]]?
    var nestedInstructions: [[String]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 設定導航欄的背景顏色
        navigationController?.navigationBar.barTintColor = UIColor.white
        self.tabBarController?.tabBar.isHidden = true
        if let nestedInstructions = nestedInstructions {
            for (index, steps) in nestedInstructions.enumerated() {
                print("導航段落 \(index):")
                for instruction in steps {
                    print("指令: \(instruction)")
                }
            }
        }
        self.navigationItem.largeTitleDisplayMode = .never
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
        setupUI()
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
            
            self.checkDistanceForCurrentTarget(from: currentLocation)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func setupUI() {
        view.addSubview(progressView)
        
        progressView.backgroundColor = .clear // Transparent background
        progressView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.width.equalTo(20) // Width of the progress bar
        }
        
        for _ in 0..<places.count {
            let dot = UIView()
            dot.backgroundColor = .lightGray
            dot.layer.cornerRadius = 5 // Circular dots
            progressView.addSubview(dot)
            
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(10) // Size of dots
                make.centerX.equalToSuperview()
            }
            
            progressDots.append(dot)
        }
        
        for (index, dot) in progressDots.enumerated() {
            dot.snp.makeConstraints { make in
                if index == 0 {
                    make.top.equalToSuperview().offset(20)
                } else {
                    make.top.equalTo(progressDots[index - 1].snp.bottom).offset(30)
                }
            }
        }
    }
    
    func updateProgress(for placeIndex: Int) {
        if placeIndex < progressDots.count {
            let dot = progressDots[placeIndex]
            dot.backgroundColor = .blue // Change color to indicate completion
        }
    }
    
    @objc func shareButtonTapped() {
        let imageUploadVC = PhotoUploadViewController()
        self.navigationController?.pushViewController(imageUploadVC, animated: true)
    }
    
    
    func loadPoemDataFromFirebase() {
        
        self.loadedPoem = nil
        
        guard let trip = trip else { return }
        
        FirebaseManager.shared.loadPoemById(trip.poemId) { [weak self] poem in
            guard let self = self else { return }
            
            self.loadedPoem = poem
            
            // 更新界面
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func updatePoemData(poem: Poem) {
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
            
            print("placesArray loaded from Firebase: \(placesArray)")
            self.places = trip.placeIds.compactMap { placeId in
                return placesArray.first(where: { $0.id == placeId })
            }
            
            print("Sorted places: \(self.places)")
            if let lastCompletedPlaceId = self.completedPlaceIds.last,
               let lastCompletedIndex = self.places.firstIndex(where: { $0.id == lastCompletedPlaceId }) {
                self.currentTargetIndex = lastCompletedIndex + 1
            } else {
                self.currentTargetIndex = 0
            }
            self.placeName = self.places.map { $0.name }
            
            DispatchQueue.main.async {
                if self.buttonState.count != self.places.count {
                    self.buttonState = Array(repeating: false, count: self.places.count)
                }
                self.tableView.reloadData()
                self.locationManager.startUpdatingLocation()
                self.locationManager.onLocationUpdate = { [weak self] currentLocation in
                    guard let self = self else { return }
                    self.checkDistanceForCurrentTarget(from: currentLocation)
                }
            }
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
        
        guard section == 0 else {
                return nil
            }
        
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
        headerView.layer.cornerRadius = 20
        
        let titleLabel = UILabel()
        titleLabel.text = poem.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
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
        poetLabel.textColor = .white
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
        contentLabel.textColor = .white
        contentLabel.textAlignment = .center
        contentLabel.numberOfLines = 0
        headerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(poetLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-10) // Add this line
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return section == 0 ? UITableView.automaticDimension : 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 35
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // 每個地點對應一個 section，根據嵌套數列的數量確定 section 數量
        return nestedInstructions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < places.count else {
                return 0
            }

            if completedPlaceIds.contains(places[section].id) {
                return 0
            }

            return nestedInstructions?[section].count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < places.count else {
            return nil
        }

        // 創建透明的 containerView
        let containerView = UIView()
        containerView.backgroundColor = .clear // 透明背景
        
        // 創建 footerView，並添加到 containerView 中
        let footerView = UIView()
        footerView.backgroundColor = .systemGray3
        footerView.layer.cornerRadius = 20
        footerView.layer.masksToBounds = true // 讓角落變成圓角
        containerView.addSubview(footerView)

        // 設置 footerView 的內縮約束，讓它看起來內縮
        footerView.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(10)
            make.bottom.equalTo(containerView).offset(-10)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
        }

        // 創建 placeLabel 並加入 footerView
        let placeLabel = UILabel()
        let place = places[section]
        placeLabel.text = place.name
        placeLabel.font = UIFont.systemFont(ofSize: 18)
        placeLabel.numberOfLines = 0
        footerView.addSubview(placeLabel)

        placeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        // 創建 completeButton 並加入 footerView
        let completeButton = UIButton(type: .system)
        completeButton.setTitle("完成", for: .normal)
        completeButton.isEnabled = !completedPlaceIds.contains(place.id)
        completeButton.tag = section // 將 section 設置為按鈕的 tag 以便識別
        completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)
        footerView.addSubview(completeButton)

        completeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        return containerView
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "instructionCell", for: indexPath)
        cell.selectionStyle = .none
        if let instruction = nestedInstructions?[indexPath.section][indexPath.row] {
            cell.textLabel?.text = instruction
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .light)
            cell.textLabel?.numberOfLines = 0 // 多行顯示導航指令
        }
        
        cell.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.masksToBounds = true
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        
        return cell
    }
    
    func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "instructionCell")
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func didTapCompleteButton(_ sender: UIButton) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let trip = trip else { return }
        
        let sectionIndex = sender.tag
        
        guard sectionIndex < places.count else {
            return
        }
        
        let place = places[sectionIndex]
        let placeId = place.id
        
        guard sectionIndex == currentTargetIndex else {
            return
        }
        
        let tripId = trip.id
        
        FirebaseManager.shared.updateCompletedTripAndPlaces(for: userId, trip: trip, placeId: placeId) { success in
            if success {
                print("地点 \(placeId) 和行程 \(tripId) 成功更新")
                
                DispatchQueue.main.async {
                    sender.isSelected = true
                    sender.isEnabled = false
                    self.completedPlaceIds.append(placeId)
                    self.buttonState[self.currentTargetIndex] = false // 禁用已完成地点的按钮
                    self.currentTargetIndex += 1 // 更新到下一個地點
                    self.tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic) // 更新當前 section
                }
            } else {
                print("更新失败")
            }
        }
    }
    
}
