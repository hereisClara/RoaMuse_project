//
//  EstablishViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import UIKit
import SnapKit
import WeatherKit
import CoreLocation
import FirebaseFirestore
import MJRefresh
import MapKit

class EstablishViewController: UIViewController {
    
    var poemIdsInCollectionTripsHandler: (([String]) -> Void)?
    var poemsFromFirebase: [[String: Any]] = []
    var fittingPoemArray = [[String: Any]]()
    var poemIdsInCollectionTrips = [String]()
    var trip: Trip?
    var city = String()
    var districts = [String]()
    var keywordToLineMap = [String: String]()
    var matchingPlaces = [(keyword: String, place: Place)]()
    var placePoemPairs = [PlacePoemPair]()
    private let recommendRandomTripView = UIView()
    private let styleTableView = UITableView()
    private let styleLabel = UILabel()
    var radiusLabel = UILabel()
    var radiusSlider = UISlider()
    private var selectionTitle = String()
    private var styleTag = Int()
    private let popupView = PopUpView()
    let locationManager = LocationManager()
    let activityIndicator = GradientActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    var searchRadius: CLLocationDistance = 15000
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "建立"
        if let customFont = UIFont(name: "NotoSerifHK-Black", size: 40) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: UIColor.deepBlue, // 修改顏色
                .font: customFont // 設置字體
            ]
        }
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        styleTableView.register(StyleTableViewCell.self, forCellReuseIdentifier: "styleCell")
        locationManager.requestWhenInUseAuthorization()
        popupView.delegate = self
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        
        view.addSubview(activityIndicator)
        setupActivityIndicator()
        
        poemIdsInCollectionTripsHandler?(poemIdsInCollectionTrips)
        print(poemIdsInCollectionTrips)
    }
    
    func setupActivityIndicator() {
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view) // 設置指示器在視圖的中央
        }
        
        activityIndicator.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        tabBarController?.tabBar.isHidden = false
    }
    
    func setupUI() {
        view.addSubview(recommendRandomTripView)
        recommendRandomTripView.addSubview(styleLabel)
        
        let circleView = UIView()
        circleView.backgroundColor = .backgroundGray
        circleView.layer.cornerRadius = 20 // 圆形
        circleView.layer.masksToBounds = true
        recommendRandomTripView.addSubview(circleView)
        
        // 创建并设置右侧的按钮
        let sliderButton = UIButton(type: .system)
        sliderButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        sliderButton.tintColor = .deepBlue
        circleView.addSubview(sliderButton)
        
        recommendRandomTripView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(120)
        }
        
        recommendRandomTripView.layer.cornerRadius = 20

        // 风格标签布局
        styleLabel.snp.makeConstraints { make in
            make.leading.equalTo(recommendRandomTripView).offset(16)
            make.top.equalTo(recommendRandomTripView).offset(12)
        }
        styleLabel.lineSpacing = 8
        styleLabel.numberOfLines = 0
        styleLabel.text = "今天我想來點⋯⋯"
        styleLabel.textColor = .forBronze
        styleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 28)
        
        recommendRandomTripView.backgroundColor = .deepBlue

        sliderButton.snp.makeConstraints { make in
            make.center.equalTo(circleView)
            make.width.height.equalTo(30)
        }

        circleView.snp.makeConstraints { make in
            make.trailing.equalTo(recommendRandomTripView).offset(-16)
            make.top.equalTo(recommendRandomTripView).offset(16)
            make.width.height.equalTo(40)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recommendRandomTripView.addGestureRecognizer(tapGesture)
        
        sliderButton.addTarget(self, action: #selector(showSliderPopup), for: .touchUpInside)
    }
    
    @objc func showSliderPopup() {
        
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                return
            }
        
        var radiusLabel = UILabel()
        var radiusSlider = UISlider()
        // 创建一个全屏半透明背景视图
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        keyWindow.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(keyWindow) // 全屏覆盖
        }
        
        // 创建一个弹窗视图
        let popupView = UIView()
        popupView.backgroundColor = .backgroundGray.withAlphaComponent(0.9)
        popupView.layer.cornerRadius = 15
        backgroundView.addSubview(popupView)
        
        popupView.snp.makeConstraints { make in
            make.center.equalTo(backgroundView)
            make.width.equalTo(view).multipliedBy(0.8)
            make.height.equalTo(200)
        }
        
        radiusLabel.text = "範圍半徑：\(searchRadius) 公尺"
        radiusLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        radiusLabel.textAlignment = .center
        popupView.addSubview(radiusLabel)
        
        radiusLabel.snp.makeConstraints { make in
            make.top.equalTo(popupView).offset(20)
            make.centerX.equalTo(popupView)
        }
        
        radiusSlider.minimumValue = 1000
        radiusSlider.maximumValue = 15000
        radiusSlider.value = Float(searchRadius)  // 初始值为 1000
        popupView.addSubview(radiusSlider)
        
        radiusSlider.snp.makeConstraints { make in
            make.top.equalTo(radiusLabel.snp.bottom).offset(20)
            make.leading.equalTo(popupView).offset(20)
            make.trailing.equalTo(popupView).offset(-20)
        }
        
        // 添加Slider变化监听器
        radiusSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        // 添加关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("關閉", for: .normal)
        closeButton.tintColor = .systemBlue
        popupView.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(radiusSlider.snp.bottom).offset(20)
            make.centerX.equalTo(popupView)
        }
        
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
        
        // 保存 UILabel 和 UISlider 作为属性
        self.radiusLabel = radiusLabel
        self.radiusSlider = radiusSlider
    }

    @objc func sliderValueChanged(_ sender: UISlider) {
        
        let roundedValue = round(sender.value / 1000) * 1000
        sender.value = roundedValue
        
        radiusLabel.text = "範圍半徑：\(Int(roundedValue)) 公尺"
    }
    
    @objc func dismissPopup(_ sender: UIButton) {
        searchRadius = CLLocationDistance(radiusSlider.value)
        
        sender.superview?.superview?.removeFromSuperview() // 移除弹窗
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        randomTripEntryButtonDidTapped()
    }
    
    func setupPullToRefresh() {
        styleTableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshData))
    }
    
    @objc func refreshData() {
        FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
            self.postsArray.insert(contentsOf: newPosts, at: 0)
            self.styleTableView.reloadData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.styleTableView.mj_header?.endRefreshing()
        }
    }
//    MARK: work
}

extension EstablishViewController {
    
    @objc func randomTripEntryButtonDidTapped() {
        recommendRandomTripView.isUserInteractionEnabled = false
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        
        locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            self.locationManager.onLocationUpdate = nil
            
            self.processWithCurrentLocation(currentLocation)
        }
        locationManager.requestLocation()
    }
    
    func processWithCurrentLocation(_ currentLocation: CLLocation) {
            
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
        }

        // 設置一個超時計時器，15秒後顯示警告彈窗
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showNoPlacesFoundAlert() // 顯示警告彈窗
                self.recommendRandomTripView.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
        }
        
        // 在主線程中安排超時計時器
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeoutWorkItem)
        
        PoemCollectionManager.shared.loadPoemIdsFromFirebase(forUserId: userId) {
            DispatchQueue.global(qos: .userInitiated).async {
                FirebaseManager.shared.loadAllPoems { poems in
                    // 如果請求成功，取消超時計時器
                    timeoutWorkItem.cancel()
                    
                    let filteredPoems = poems.filter { poem in
                        return poem.tag == self.styleTag && !PoemCollectionManager.shared.isPoemAlreadyInCollection(poem.id)
                    }
                    if let randomPoem = filteredPoems.randomElement() {
                        self.processPoemText(randomPoem.content.joined(separator: "\n")) { keywords, keywordToLineMap in
                            self.keywordToLineMap = keywordToLineMap
                            self.generateTripFromKeywords(keywords, poem: randomPoem, startingFrom: currentLocation) { trip in
                                if let trip = trip {
                                    let places = self.matchingPlaces.map { $0.place }
                                    self.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: places) { totalTravelTime, routes in
                                        DispatchQueue.main.async {
                                            self.popupView.showPopup(on: self.view, with: trip, city: self.city, districts: self.districts)
                                            self.trip = trip
                                            self.recommendRandomTripView.isUserInteractionEnabled = true
                                            self.activityIndicator.stopAnimating()
                                            self.activityIndicator.isHidden = true
                                        }
                                        FirebaseManager.shared.saveCityToTrip(tripId: trip.id, poemId: randomPoem.id, city: self.city) { error in
                                            if let error = error {
                                                print("Error saving data: \(error.localizedDescription)")
                                            } else {
                                                print("Data saved successfully")
                                            }
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.recommendRandomTripView.isUserInteractionEnabled = true
                                        self.activityIndicator.stopAnimating()
                                        self.activityIndicator.isHidden = true
                                    }
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.recommendRandomTripView.isUserInteractionEnabled = true
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    func processPoemText(_ inputText: String, completion: @escaping ([String], [String: String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard let model = try? poemLocationNLP3(configuration: .init()) else { return }
            
            var allResults = [String]()
            var keywordToLineMap = [String: String]()
            
            for segment in textSegments {
                do {
                    let prediction = try model.prediction(text: segment)
                    let keyword = prediction.label
                    allResults.append(keyword)
                    keywordToLineMap[keyword] = segment
                } catch {
                    print("Error in prediction: \(error)")
                }
            }
            DispatchQueue.main.async {
                completion(Array(Set(allResults)), keywordToLineMap)
            }
        }
    }
    
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            var foundValidPlace = false
            self.city = ""
            self.districts.removeAll()
            self.matchingPlaces.removeAll()
            
            for keyword in keywords {
                dispatchGroup.enter()
                self.processKeywordPlaces(keyword: keyword, currentLocation: currentLocation, dispatchGroup: dispatchGroup) { validPlaceFound in
                    if validPlaceFound {
                        foundValidPlace = true
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
                if foundValidPlace, self.matchingPlaces.count > 0 {
                    self.saveTripToFirebase(poem: poem) { trip in
                        DispatchQueue.main.async {
                            completion(trip)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func processKeywordPlaces(keyword: String, currentLocation: CLLocation, dispatchGroup: DispatchGroup, completion: @escaping (Bool) -> Void) {
        FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
            // 找到所有附近的地点
            let nearbyPlaces = places.filter { place in
                let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                let distance = currentLocation.distance(from: placeLocation)
                return distance <= self.searchRadius
            }
            
            if let randomPlace = nearbyPlaces.randomElement() {
                if !self.matchingPlaces.contains(where: { $0.place.id == randomPlace.id }) {
                    
                    self.matchingPlaces.append((keyword: keyword, place: randomPlace))
                    
                    let placeLocation = CLLocation(latitude: randomPlace.latitude, longitude: randomPlace.longitude)
                    self.reverseGeocodeLocation(placeLocation) { city, district in
                        if let city = city, let district = district {
                            if self.city.isEmpty {
                                self.city = city
                            }
                            if !self.districts.contains(district) {
                                self.districts.append(district)
                            }
                        }
                    }
                    completion(true) // 标记为成功找到地点
                } else {
                    completion(false) // 如果已经存在该地点
                    
                }
            } else {
                
                PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation, radius: self.searchRadius) { foundPlaces, hasFoundPlace  in
                    
                    if hasFoundPlace == false{
                        DispatchQueue.main.async {
                            self.showNoPlacesFoundAlert()
                        }
                    }
                    if let newPlace = foundPlaces.first {
                        PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                            if let savedPlace = savedPlace {
                                if !self.matchingPlaces.contains(where: { $0.place.id == savedPlace.id }) {
                                    self.matchingPlaces.append((keyword: keyword, place: savedPlace))
                                }
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    func showNoPlacesFoundAlert() {
        let alert = UIAlertController(title: "提示", message: "未找到符合條件的地點", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, completion: @escaping (TimeInterval?, MKRoute?) -> Void) {
        let request = MKDirections.Request()
        
        let sourcePlacemark = MKPlacemark(coordinate: startLocation)
        let destinationPlacemark = MKPlacemark(coordinate: endLocation)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        
        request.transportType = .automobile  // 或者 .walking
        
        // 計算路線
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                
                completion(nil, nil)
                return
            }
            
            if let route = response?.routes.first {
                
                completion(route.expectedTravelTime, route)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [Place], completion: @escaping (TimeInterval?, [[String]]?) -> Void) {
        var totalTime: TimeInterval = 0
        var nestedInstructions = [[String]]()  // 用來存放每段路線的指令數列
        let dispatchGroup = DispatchGroup()
        
        // 確保有地點可供計算
        guard !places.isEmpty else {
            
            completion(nil, nil)
            return
        }
        
        totalTime = 0
        nestedInstructions.removeAll()
        
        // Step 1: 計算從當前位置到第一個地點的時間
        if let firstPlace = places.first {
            let firstPlaceLocation = CLLocationCoordinate2D(latitude: firstPlace.latitude, longitude: firstPlace.longitude)
            
            dispatchGroup.enter()
            calculateRoute(from: currentLocation, to: firstPlaceLocation) { travelTime, route in
                if let travelTime = travelTime, let route = route {
                    totalTime += travelTime
                    
                    // 創建導航指令數列
                    var stepInstructions = [String]()
                    for step in route.steps {
                        let instruction = step.instructions
                        stepInstructions.append(instruction)
                    }
                    nestedInstructions.append(stepInstructions)  // 加入嵌套數列
                }
                dispatchGroup.leave()
            }
        }
        
        // Step 2: 計算地點之間的時間
        if places.count > 1 {
            for num in 0..<(places.count - 1) {
                let startLocation = CLLocationCoordinate2D(latitude: places[num].latitude, longitude: places[num].longitude)
                let endLocation = CLLocationCoordinate2D(latitude: places[num + 1].latitude, longitude: places[num + 1].longitude)
                
                dispatchGroup.enter()
                calculateRoute(from: startLocation, to: endLocation) { travelTime, route in
                    if let travelTime = travelTime, let route = route {
                        totalTime += travelTime
                        
                        // 創建導航指令數列
                        var stepInstructions = [String]()
                        for step in route.steps {
                            let instruction = step.instructions
                            stepInstructions.append(instruction)
                        }
                        nestedInstructions.append(stepInstructions)  // 加入嵌套數列
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // Step 3: 返回總時間和詳細導航指令
        dispatchGroup.notify(queue: .main) {
            completion(totalTime, nestedInstructions)
        }
    }
    
    
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil, nil)
            } else if let placemark = placemarks?.first {
                
                let city = placemark.administrativeArea
                let cityName = cityCodeMapping[city ?? ""]
                let district = placemark.subLocality
                
                if let cityName = cityName {
                    completion(cityName, district)
                    print("cityName: \(cityName)")
                }
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func createNestedRouteInstructions(routesArray: [[MKRoute]]) -> [[[String: Any]]] {
        var nestedRouteInstructions = [[[String: Any]]]()
        
        // 遍歷每一段路線
        for routeArray in routesArray {
            var stepInstructions = [[String: Any]]()  // 用來保存每一段路線的步驟
            
            if let route = routeArray.first {
                // 遍歷該段路線中的每個步驟
                for step in route.steps {
                    let stepData: [String: Any] = [
                        "instructions": step.instructions,
                        "distance": step.distance,
                        "notice": step.notice ?? "無"  // `notice` 可能為 nil，所以提供預設值
                    ]
                    stepInstructions.append(stepData)
                }
            }
            
            // 將每段路線的步驟保存到外層數組中
            nestedRouteInstructions.append(stepInstructions)
        }
        
        return nestedRouteInstructions
    }
    
}

extension EstablishViewController {
    
    func saveTripToFirebase(poem: Poem, completion: @escaping (Trip?) -> Void) {
        
        let keywordPlaceIds = self.matchingPlaces.map { ["keyword": $0.keyword, "placeId": $0.place.id] }
        
        let tripData: [String: Any] = [
            "poemId": poem.id,
            "placeIds": self.matchingPlaces.map { $0.place.id },
            "keywordPlaceIds": keywordPlaceIds,
            "tag": poem.tag
        ]
        
        
        FirebaseManager.shared.checkTripExists(tripData) { exists, existingTripId in
            if exists, let existingTripId = existingTripId {
                let existingTrip = Trip(
                    poemId: poem.id,
                    id: existingTripId,
                    placeIds: self.matchingPlaces.map { $0.place.id },
                    keywordPlaceIds: nil,
                    tag: poem.tag,
                    season: nil,
                    weather: nil,
                    startTime: nil
                )
                completion(existingTrip)
            } else {
                let db = Firestore.firestore()
                var documentRef: DocumentReference? = nil
                documentRef = db.collection("trips").addDocument(data: tripData) { error in
                    if let error = error {
                        completion(nil)
                    } else {
                        guard let documentID = documentRef?.documentID else {
                            completion(nil)
                            return
                        }
                        
                        // 更新 tripId
                        documentRef?.updateData(["id": documentID]) { error in
                            if let error = error {
                                
                                completion(nil)
                            } else {
                                let trip = Trip(
                                    poemId: poem.id,
                                    id: documentID,
                                    placeIds: self.matchingPlaces.map { $0.place.id },
                                    keywordPlaceIds: nil,
                                    tag: poem.tag,
                                    season: nil,
                                    weather: nil,
                                    startTime: nil
                                )
                                
                                self.getPoemPlacePair()  // Make sure placePoemPairs is populated
                                self.saveSimplePlacePoemPairsToFirebase(tripId: documentID, simplePairs: self.placePoemPairs) { success in
                                    if success {
                                        print("Successfully saved placePoemPairs to Firebase.")
                                    } else {
                                        print("Failed to save placePoemPairs to Firebase.")
                                    }
                                    completion(trip)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension EstablishViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip
        tripDetailVC.matchingPlaces = self.matchingPlaces // 确保 TripDetailViewController 能处理新的数据结构
        tripDetailVC.keywordToLineMap = self.keywordToLineMap // 传递 keywordToLineMap
        
        if let currentLocation = locationManager.currentLocation?.coordinate {
            let places = matchingPlaces.map { $0.place } // 提取 Place 数组
            calculateTotalRouteTimeAndDetails(from: currentLocation, places: places) { [weak self] totalTravelTime, nestedInstructions in
                guard let self = self else { return }
                
                if let totalTravelTime = totalTravelTime, let nestedInstructions = nestedInstructions {
                    tripDetailVC.totalTravelTime = totalTravelTime // 传递总交通时间
                    tripDetailVC.nestedInstructions = nestedInstructions // 传递嵌套的导航指令数组
                }
                
                // 跳转到 TripDetailViewController
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(tripDetailVC, animated: true)
                }
            }
        }
    }
    
}

extension EstablishViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        styleTableView.dataSource = self
        styleTableView.delegate = self
        styleTableView.separatorStyle = .none
        
        view.addSubview(styleTableView)
        styleTableView.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView.snp.bottom).offset(12)
            make.width.equalTo(recommendRandomTripView)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.centerX.equalTo(view)
        }
        
        styleTableView.rowHeight = UITableView.automaticDimension
        styleTableView.estimatedRowHeight = 200
        styleTableView.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTableView.dequeueReusableCell(withIdentifier: "styleCell", for: indexPath) as? StyleTableViewCell
        
        cell?.titleLabel.text = styles[indexPath.row].name
        cell?.descriptionLabel.text = styles[indexPath.row].introduction
        cell?.selectionStyle = .none
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? StyleTableViewCell {
            // 在這裡執行你要對 cell 的操作
            selectionTitle = cell.titleLabel.text ?? "" // 改變 cell 的背景顏色
            styleTag = Int(indexPath.row)
            updateStyleLabel(with: "＃\(selectionTitle)")
        }
    }
}

extension EstablishViewController {
    
    func getPoemPlacePair() {
        
        placePoemPairs.removeAll()
        
        for matchingPlace in matchingPlaces {
            let keyword = matchingPlace.keyword
            
            if let poemLine = keywordToLineMap[keyword] {
                let placePoemPair = PlacePoemPair(placeId: matchingPlace.place.id, poemLine: poemLine)
                placePoemPairs.append(placePoemPair)
            }
        }
    }
    
    func saveSimplePlacePoemPairsToFirebase(tripId: String, simplePairs: [PlacePoemPair], completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let tripRef = db.collection("trips").document(tripId)
        
        let placePoemData = simplePairs.map { pair in
            return [
                "placeId": pair.placeId,
                "poemLine": pair.poemLine
            ] as [String : Any]
        }
        
        tripRef.updateData([
            "placePoemPairs": placePoemData
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
                completion(false)
            } else {
                print("Document successfully updated with placePoemPairs")
                completion(true)
            }
        }
    }
    
    func updateStyleLabel(with title: String) {
        let fullText = "今天我想來點\n\(title) 的風格"
        
        // 建立 NSMutableAttributedString 來應用樣式
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // 設定第一行的字體和顏色
        let firstLineRange = (fullText as NSString).range(of: "今天我想來點")
        attributedString.addAttribute(.font, value: UIFont(name: "NotoSerifHK-Black", size: 28)!, range: firstLineRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.backgroundGray, range: firstLineRange)
        
        // 設定選擇的風格的字體和顏色
        let selectionRange = (fullText as NSString).range(of: title)
        attributedString.addAttribute(.font, value: UIFont(name: "NotoSerifHK-Black", size: 34)!, range: selectionRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.accent, range: selectionRange)
        
        // 設定第三行 "的風格" 的字體和顏色
        let thirdLineRange = (fullText as NSString).range(of: " 的風格")
        attributedString.addAttribute(.font, value: UIFont(name: "NotoSerifHK-Black", size: 28)!, range: thirdLineRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.backgroundGray, range: thirdLineRange)
        
        // 將設定後的 attributed string 設定到 label
        styleLabel.attributedText = attributedString
    }

}
