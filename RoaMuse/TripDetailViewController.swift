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
    
    var buttonContainer: UIStackView = UIStackView()
    var transportButtons: [UIButton] = []
    var selectedTransportButton: UIButton?
    var isExpanded: Bool = false
    var buttonsViewWidthConstraint: Constraint?
    var selectedTransportType: MKDirectionsTransportType = .automobile
    var transportBackgroundView: UIView?
    var transportButtonsViewWidthConstraint: Constraint?
    
    var keywordToLineMap = [String: String]()
    var matchingPlaces = [(keyword: String, place: Place)]()
    var placePoemPairs = [PlacePoemPair]()
    
    let buttonTitles = ["car.fill", "figure.walk", "bicycle", "tram.fill"]
    
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
    
    var footerViews = [Int: UIView]()
    
    private var isMapVisible: Bool = false
    var isFlipped: [Int: Bool] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.barTintColor = UIColor.white
        
        print("============", matchingPlaces)
        print("============", keywordToLineMap)
        getPoemPlacePair()
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
//        setupTransportButtons()
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
        
//        // 开始位置更新
//        self.locationManager.startUpdatingLocation()
//        self.locationManager.onLocationUpdate = { [weak self] currentLocation in
//            guard let self = self else { return }
//            
//            self.checkDistanceForCurrentTarget(from: currentLocation)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
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
    }
    
    func setupProgressDots() {
        // 移除之前的进度点
        for dot in progressDots {
            dot.removeFromSuperview()
        }
        progressDots.removeAll()
        
        // 添加新的进度点
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
    
    func getPoemPlacePair() {
        
        placePoemPairs.removeAll()
        
        for matchingPlace in matchingPlaces {
            let keyword = matchingPlace.keyword
            
            if let poemLine = keywordToLineMap[keyword] {
                let placePoemPair = PlacePoemPair(placeId: matchingPlace.place.id, poemLine: poemLine)
                placePoemPairs.append(placePoemPair)
            }
        }
        
        print("++++++  ", placePoemPairs)
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
        
        guard let trip = trip else { return }
        
        self.places = self.matchingPlaces.map { $0.place }
        
        self.places.sort { (place1, place2) -> Bool in
                guard let index1 = trip.placeIds.firstIndex(of: place1.id),
                      let index2 = trip.placeIds.firstIndex(of: place2.id) else {
                    return false
                }
                return index1 < index2
            }
        
        let placeIds = trip.placeIds
        
        if placeIds.isEmpty {
            print("行程中無地點資料")
            return
        }
        
        FirebaseManager.shared.loadPlaces(placeIds: placeIds) { [weak self] (placesArray) in
            guard let self = self else { return }
            
            print("placesArray loaded from Firebase: \(placesArray)")
            
            self.matchingPlaces = trip.placeIds.compactMap { placeId in
                        if let place = placesArray.first(where: { $0.id == placeId }) {
                            return (keyword: "未知关键字", place: place)
                        } else {
                            return nil
                        }
                    }
            self.places = self.matchingPlaces.map { $0.place }
            print("Sorted matchingPlaces: \(self.matchingPlaces)")
            
            if let lastCompletedPlaceId = self.completedPlaceIds.last,
               let lastCompletedIndex = self.places.firstIndex(where: { $0.id == lastCompletedPlaceId }) {
                self.currentTargetIndex = lastCompletedIndex + 1
            } else {
                self.currentTargetIndex = 0
            }
            
            self.placeName = self.places.map { $0.name }
            
            DispatchQueue.main.async {
                // 初始化 buttonState
                self.buttonState = Array(repeating: false, count: self.places.count)
                
                // 设置进度点
                self.setupProgressDots()
                
                // 重新加载表格视图
                self.tableView.reloadData()
                
                // **檢查已完成的地點並設置狀態**
                for (index, place) in self.places.enumerated() {
                    if self.completedPlaceIds.contains(place.id), let footerView = self.footerViews[index] {
                        self.setupCompletedFooterView(footerView: footerView, sectionIndex: index)
                    }
                }
                
                // 開始位置更新
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
        
        guard currentTargetIndex < buttonState.count else {
            print("buttonState 未正确初始化")
            return
        }
        
        let place = places[currentTargetIndex]
        let targetLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
        let distance = currentLocation.distance(from: targetLocation)
        print("距离 \(place.name): \(distance) 米")
        
        let isWithinThreshold = distance <= distanceThreshold
        
        if isWithinThreshold != buttonState[currentTargetIndex] {
            buttonState[currentTargetIndex] = isWithinThreshold
            print("距离 \(isWithinThreshold ? "小于或等于" : "大于") \(distanceThreshold) 米，地点 \(place.name) \(isWithinThreshold ? "可用" : "不可用")")
            tableView.reloadRows(at: [IndexPath(row: 0, section: currentTargetIndex)], with: .none)
        }
    }
}

extension TripDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else {
            return nil
        }
        
        guard let poem = loadedPoem else {
            return createLoadingHeaderView()
        }
        
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.isUserInteractionEnabled = true // 确保容器视图可以交互
        
        let headerView = createHeaderView(poem: poem)
        headerView.isUserInteractionEnabled = true // 确保 headerView 可以交互
        containerView.addSubview(headerView)
        
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        let buttonsView = createButtonsView()
        containerView.addSubview(buttonsView)
        
        buttonsView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        return containerView
    }
    
    // 拆分函數，用於創建加載中的標題視圖
    private func createLoadingHeaderView() -> UIView {
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
    
    // 拆分函數，用於創建標題視圖
    private func createHeaderView(poem: Poem) -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(resource: .deepBlue)
        headerView.layer.cornerRadius = 20
        
        let titleLabel = createLabel(text: poem.title, font: UIFont(name: "NotoSerifHK-Black", size: 22) ?? UIFont.systemFont(ofSize: 22))
        
        headerView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(12)
        }
        
        let poetLabel = createLabel(text: poem.poetry, font: UIFont(name: "NotoSerifHK-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20))
        headerView.addSubview(poetLabel)
        
        poetLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
        }
        
        let contentLabel = createLabel(text: poem.content.joined(separator: "\n"), font: UIFont(name: "NotoSerifHK-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18))
        contentLabel.numberOfLines = 0
        headerView.addSubview(contentLabel)
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(poetLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        return headerView
    }
    
    // 拆分函數，用於創建通用的標籤
    private func createLabel(text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.textAlignment = .center
        label.font = font
        return label
    }
    
    private func createButtonsView() -> UIView {
        let buttonsView = UIView()
        buttonsView.isUserInteractionEnabled = true
        
        // 设置 locateButton
        let locationButton = UIButton()
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = .white
        locationButton.backgroundColor = .systemGray4
        locationButton.layer.cornerRadius = 25
        locationButton.addTarget(self, action: #selector(didTapLocateButton(_:)), for: .touchUpInside)
        locationButton.isUserInteractionEnabled = true
        
        buttonsView.addSubview(locationButton)
        
        locationButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
        
        // 创建用于放置交通工具按钮的容器视图
        let transportButtonsView = UIView()
        transportButtonsView.isUserInteractionEnabled = true
        buttonsView.addSubview(transportButtonsView)
        
        transportButtonsView.snp.makeConstraints { make in
            make.leading.equalTo(locationButton.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            // 添加宽度约束，初始为单个按钮的宽度
            transportButtonsViewWidthConstraint = make.width.equalTo(50).constraint
        }
        
        // 添加背景视图
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemGray4
        backgroundView.layer.cornerRadius = 25
        backgroundView.isHidden = true // 初始隐藏
        transportButtonsView.addSubview(backgroundView)
        // 将背景视图放在所有按钮的后面
        transportButtonsView.sendSubviewToBack(backgroundView)
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(transportButtonsView)
        }
        
        // 创建按钮容器 StackView
        buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 12
        buttonContainer.isUserInteractionEnabled = true
        transportButtonsView.addSubview(buttonContainer)
        
        buttonContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 创建交通工具按钮
        let transportOptions = ["car.fill", "bicycle", "tram.fill", "figure.walk"]
        transportButtons = []
        
        for (index, icon) in transportOptions.enumerated() {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: icon), for: .normal)
            button.tintColor = .white
            button.backgroundColor = .clear // 未选中时背景为透明
            button.layer.cornerRadius = 25
            button.tag = index
            button.isUserInteractionEnabled = true
            // 添加点击事件处理器
            button.addTarget(self, action: #selector(transportButtonTapped(_:)), for: .touchUpInside)
            transportButtons.append(button)
        }
        
        // 设置初始选中按钮为第一个
        selectedTransportButton = transportButtons.first
        selectedTransportButton?.backgroundColor = .deepBlue
        
        // 将所有按钮添加到 buttonContainer
        for button in transportButtons {
            buttonContainer.addArrangedSubview(button)
        }
        
        // 初始状态下，只显示 selectedTransportButton
        updateTransportButtonsDisplay()
        
        // 保存背景视图，便于在其他方法中使用
        self.transportBackgroundView = backgroundView
        
        return buttonsView
    }
    
    
    private func updateTransportButtonsDisplay() {
        if isExpanded {
            // 显示所有按钮
            for button in transportButtons {
                button.isHidden = false
            }
            // 显示背景视图
            transportBackgroundView?.isHidden = false
            
            // 计算总宽度
            let buttonWidth: CGFloat = 50
            let buttonSpacing: CGFloat = 12
            let totalWidth = CGFloat(transportButtons.count) * buttonWidth + CGFloat(transportButtons.count - 1) * buttonSpacing
            
            // 更新宽度约束
            transportButtonsViewWidthConstraint?.update(offset: totalWidth)
        } else {
            // 只显示选中的按钮
            for button in transportButtons {
                button.isHidden = (button != selectedTransportButton)
            }
            // 隐藏背景视图
            transportBackgroundView?.isHidden = true
            
            // 更新宽度约束为单个按钮的宽度
            transportButtonsViewWidthConstraint?.update(offset: 50)
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func setupCompletedFooterView(footerView: UIView, sectionIndex: Int) {
        // 更新 footerView 的內容為「已完成」
        if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            placeLabel.text = "已完成"
            placeLabel.textColor = .systemGreen
        }
        
        if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            completeButton.isEnabled = false
        }
        
        // 添加「翻回去」按鈕
        let flipBackButton = UIButton(type: .system)
        flipBackButton.setTitle("翻回去", for: .normal)
        flipBackButton.addTarget(self, action: #selector(self.didTapFlipBackButton(_:)), for: .touchUpInside)
        flipBackButton.tag = sectionIndex
        footerView.addSubview(flipBackButton)
        
        // 設定按鈕約束
        flipBackButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    
    
    @objc private func transportButtonTapped(_ sender: UIButton) {
        print("transportButtonTapped called")
        if sender == selectedTransportButton {
            // 点击的是当前选中按钮，切换展开/收合
            toggleTransportButtons()
        } else {
            // 更新选中按钮的背景颜色
            selectedTransportButton?.backgroundColor = .clear
            selectedTransportButton = sender
            sender.backgroundColor = .deepBlue
            
            // 更新选中的交通方式
            selectedTransportType = transportTypeForIndex(sender.tag)
            
            // 将选中按钮移动到第一个位置
            if let index = transportButtons.firstIndex(of: sender) {
                transportButtons.remove(at: index)
                transportButtons.insert(sender, at: 0)
            }
            // 重新排列按钮
            for button in buttonContainer.arrangedSubviews {
                buttonContainer.removeArrangedSubview(button)
                button.removeFromSuperview()
            }
            for button in transportButtons {
                buttonContainer.addArrangedSubview(button)
            }
            // 收合按钮
            isExpanded = false
            UIView.animate(withDuration: 0.3) {
                self.updateTransportButtonsDisplay()
                self.view.layoutIfNeeded()
            }
            
            // 如果需要，根据新的交通方式更新地图或路线
            updateMapForSelectedTransportType()
        }
    }
    
    @objc private func toggleTransportButtons() {
        isExpanded.toggle()
        UIView.animate(withDuration: 0.3) {
            self.updateTransportButtonsDisplay()
            self.view.layoutIfNeeded()
        }
    }
    
    
    private func transportTypeForIndex(_ index: Int) -> MKDirectionsTransportType {
        switch index {
        case 0:
            return .automobile
        case 1:
            return .walking
        case 2:
            return .transit
        case 3:
            return .walking
        default:
            return .automobile
        }
    }
    
    private func updateMapForSelectedTransportType() {
        // 根据 selectedTransportType 更新地图上的路线
        // 例如，重新计算路线并刷新地图
        
        // 如果地图当前可见，更新地图
        if isMapVisible {
            tableView.reloadRows(at: [IndexPath(row: 0, section: currentTargetIndex)], with: .none)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? UITableView.automaticDimension : 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isMapVisible && indexPath.section == currentTargetIndex {
            return 200 // 顯示地圖的高度
        } else {
            return 0 // 隱藏cell時高度為0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        places.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
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
        //        completeButton.setTitle("完成", for: .normal)
        completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        completeButton.setImage(UIImage(systemName: "checkmark.circle"), for: .disabled)
        completeButton.isEnabled = !completedPlaceIds.contains(place.id)
        completeButton.tag = section
        completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)
        footerView.addSubview(completeButton)
        
        completeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        
        if completedPlaceIds.contains(place.id) {
            setupCompletedFooterView(footerView: footerView, sectionIndex: section)
        }
        
        footerViews[section] = footerView
        
        return containerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath) as? MapTableViewCell ?? MapTableViewCell()
        let place = places[indexPath.section]
        
        if isMapVisible {
            let startCoordinate = locationManager.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let destinationCoordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            cell.showMap(from: startCoordinate, to: destinationCoordinate)
        } else {
            cell.hideMap()
        }
        
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
        tableView.register(MapTableViewCell.self, forCellReuseIdentifier: "MapCell")
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func didTapLocateButton(_ sender: UIButton) {
        isMapVisible.toggle()
        
        sender.isSelected = isMapVisible
        
        if sender.isSelected {
            sender.backgroundColor = .deepBlue
        } else {
            sender.backgroundColor = .systemGray4
        }
        
        UIView.performWithoutAnimation {
            tableView.reloadSections(IndexSet(integer: currentTargetIndex), with: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 60 // 給定合理的估計高度
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
        
        // 確保只有當前目標地點可以標記為已完成
        guard sectionIndex == currentTargetIndex else {
            return
        }
        
        let tripId = trip.id
        
        // Firebase 中更新此地點為已完成
        FirebaseManager.shared.updateCompletedTripAndPlaces(for: userId, trip: trip, placeId: placeId) { success in
            if success {
                print("地点 \(placeId) 和行程 \(tripId) 成功更新")
                
                DispatchQueue.main.async {
                    if let footerView = self.footerViews[sectionIndex] {
                        // 標記此卡片已翻到「完成」一面
                        self.isFlipped[sectionIndex] = false
                        
                        // 將 footerView 進行翻轉動畫，顯示「已完成」狀態
                        UIView.transition(with: footerView, duration: 0.5, options: [.transitionFlipFromLeft], animations: {
                            
                            // 更新 footerView 的內容
                            if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                                placeLabel.text = "已完成"
                                placeLabel.textColor = .systemGreen
                            }
                            
                            if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                                completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                                completeButton.isEnabled = false
                            }
                            
                        }, completion: { _ in
                            // 顯示「翻回去」按鈕
                            let flipBackButton = UIButton(type: .system)
                            flipBackButton.setTitle("翻回去", for: .normal)
                            flipBackButton.addTarget(self, action: #selector(self.didTapFlipBackButton(_:)), for: .touchUpInside)
                            flipBackButton.tag = sectionIndex
                            footerView.addSubview(flipBackButton)
                            
                            // 設定「翻回去」按鈕約束
                            flipBackButton.snp.makeConstraints { make in
                                make.centerX.equalToSuperview()
                                make.bottom.equalToSuperview().offset(-10)
                            }
                        })
                    } else {
                        print("FooterView not found")
                    }
                }
            } else {
                print("更新失败")
            }
        }
    }
    
    @objc func didTapFlipBackButton(_ sender: UIButton) {
        let sectionIndex = sender.tag
        
        guard sectionIndex < places.count else {
            return
        }
        
        if let footerView = self.footerViews[sectionIndex] {
            // 根據當前的翻轉狀態進行對應的翻轉操作
            let isCurrentlyFlipped = isFlipped[sectionIndex] ?? false
            
            let transitionOptions: UIView.AnimationOptions = isCurrentlyFlipped ? [.transitionFlipFromRight] : [.transitionFlipFromLeft]
            
            // 更新狀態來允許來回翻轉
            UIView.transition(with: footerView, duration: 0.5, options: transitionOptions, animations: {
                if isCurrentlyFlipped {
                    // 翻回地名的一面
                    if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                        placeLabel.text = self.places[sectionIndex].name
                        placeLabel.textColor = .black
                    }
                    
                    if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                        completeButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
                        completeButton.isEnabled = true
                    }
                } else {
                    // 翻到已完成的一面
                    if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                        placeLabel.text = "已完成"
                        placeLabel.textColor = .systemGreen
                    }
                    
                    if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                        completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                        completeButton.isEnabled = false
                    }
                }
            }, completion: { _ in
                // 更新翻轉狀態
                self.isFlipped[sectionIndex] = !isCurrentlyFlipped
            })
        }
    }
}
