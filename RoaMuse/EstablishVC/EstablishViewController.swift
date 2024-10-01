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
    
    var poemsFromFirebase: [[String: Any]] = []
    var fittingPoemArray = [[String: Any]]()
    var matchingPlaces = [Place]()
    var trip: Trip?
    var city = String()
    var districts = [String]()
    
    private let recommendRandomTripView = UIView()
    private let styleTableView = UITableView()
    private let styleLabel = UILabel()
    private var selectionTitle = String()
    private var styleTag = Int()
    private let popupView = PopUpView()
    let locationManager = LocationManager()
    
    let searchRadius: CLLocationDistance = 15000
    
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
        view.backgroundColor = UIColor(resource: .backgroundGray)
        styleTableView.register(StyleTableViewCell.self, forCellReuseIdentifier: "styleCell")
        
        popupView.delegate = self
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    
    func setupUI() {
        view.addSubview(recommendRandomTripView)
        recommendRandomTripView.addSubview(styleLabel)
        
        recommendRandomTripView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(150)
        }
        
        recommendRandomTripView.layer.cornerRadius = 20
        
        styleLabel.snp.makeConstraints { make in
            make.center.equalTo(recommendRandomTripView)
        }
        
        styleLabel.font = UIFont.systemFont(ofSize: 24)
        
        recommendRandomTripView.backgroundColor = .white
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recommendRandomTripView.addGestureRecognizer(tapGesture)
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
    
    @objc func randomTripEntryButtonDidTapped() {
        
        recommendRandomTripView.isUserInteractionEnabled = false
        
        locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            
            self.locationManager.stopUpdatingLocation()
            self.locationManager.onLocationUpdate = nil
            
            FirebaseManager.shared.loadAllPoems { poems in
                let filteredPoems = poems.filter { poem in
                    return poem.tag == self.styleTag
                }
                
                if let randomPoem = filteredPoems.randomElement() {
                    self.processPoemText(randomPoem.content.joined(separator: "\n")) { keywords in
                        self.generateTripFromKeywords(keywords, poem: randomPoem, startingFrom: currentLocation) { trip in
                            
                            if let trip = trip {
                                self.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: self.matchingPlaces) { totalTravelTime, routes in
                                    if let totalTravelTime = totalTravelTime {
                                        let totalMinutes = Int(totalTravelTime / 60)
                                        print("總預估交通時間：\(totalMinutes) 分鐘")
                                    }
                                    
                                    self.popupView.showPopup(on: self.view, with: trip, city: self.city, districts: self.districts)
                                }
                                
                                DispatchQueue.main.async {
                                    print("開始傳值")
                                    self.trip = trip
                                }
                            }
                            // 操作完成後重新啟用按鈕
                            self.recommendRandomTripView.isUserInteractionEnabled = true
                        }
                    }
                } else {
                    print("未找到符合該 styleTag 的詩詞")
                    // 操作完成後重新啟用按鈕
                    self.recommendRandomTripView.isUserInteractionEnabled = true
                }
            }
        }
        locationManager.startUpdatingLocation()
    }
    
    
    
    // 基於 NLP 模型分析詩詞
    func processPoemText(_ inputText: String, completion: @escaping ([String]) -> Void) {
        let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard let model = try? poemLocationNLP3(configuration: .init()) else {
            print("NLP 模型加載失敗")
            return
        }
        
        var allResults = [String]()
        for segment in textSegments {
            do {
                let prediction = try model.prediction(text: segment)
                let landscape = prediction.label
                allResults.append(landscape)
                
            } catch {
                print("分析失敗：\(error.localizedDescription)")
            }
        }
        print(Array(Set(allResults)))
        completion(Array(Set(allResults))) // 去重並返回關鍵字
    }
    
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var foundValidPlace = false
        self.city = "" // 清空現有的城市
        self.districts.removeAll() // 清空現有的行政區
        self.matchingPlaces.removeAll()
        
        for keyword in keywords {
            dispatchGroup.enter()
            processKeywordPlaces(keyword: keyword, currentLocation: currentLocation, dispatchGroup: dispatchGroup) { validPlaceFound in
                if validPlaceFound {
                    foundValidPlace = true
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if foundValidPlace, self.matchingPlaces.count >= 1 {
                self.saveTripToFirebase(poem: poem, completion: completion)
            } else {
                completion(nil)
            }
        }
    }

    func processKeywordPlaces(keyword: String, currentLocation: CLLocation, dispatchGroup: DispatchGroup, completion: @escaping (Bool) -> Void) {
        FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
            let nearbyPlaces = places.filter { place in
                let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                let distance = currentLocation.distance(from: placeLocation)
                return distance <= self.searchRadius
            }

            if !nearbyPlaces.isEmpty {
                if let randomPlace = nearbyPlaces.randomElement() {
                    if !self.matchingPlaces.contains(where: { $0.id == randomPlace.id }) {
                        self.matchingPlaces.append(randomPlace)

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
                    }
                }
                completion(true)
            } else {
                PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                    if let newPlace = foundPlaces.first {
                        PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                            if let savedPlace = savedPlace {
                                self.matchingPlaces.append(savedPlace)
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
            dispatchGroup.leave()
        }
    }

    func saveTripToFirebase(poem: Poem, completion: @escaping (Trip?) -> Void) {
        let tripData: [String: Any] = [
            "poemId": poem.id,
            "placeIds": self.matchingPlaces.map { $0.id },
            "tag": poem.tag
        ]
        
        FirebaseManager.shared.checkTripExists(tripData) { exists, existingTripId in
            if exists, let existingTripId = existingTripId {
                let existingTrip = Trip(
                    poemId: poem.id,
                    id: existingTripId,
                    placeIds: self.matchingPlaces.map { $0.id },
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
                                print("Error updating tripId: \(error)")
                                completion(nil)
                            } else {
                                let trip = Trip(
                                    poemId: poem.id,
                                    id: documentID,
                                    placeIds: self.matchingPlaces.map { $0.id },
                                    tag: poem.tag,
                                    season: nil,
                                    weather: nil,
                                    startTime: nil
                                )
                                completion(trip)
                            }
                        }
                    }
                }
            }
        }
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
                print("Error calculating route: \(error)")
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
            print("沒有地點可供計算")
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
                    print("從當前位置到第一個地點的導航指令已保存")
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
                        print("從地點 \(num) 到地點 \(num + 1) 的導航指令已保存")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // Step 3: 返回總時間和詳細導航指令
        dispatchGroup.notify(queue: .main) {
            print("總交通時間：\(totalTime) 秒")
            completion(totalTime, nestedInstructions)
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
                            "notice": step.notice ?? "無"
                        ]
                        stepInstructions.append(stepData)
                    }
                }
                nestedRouteInstructions.append(stepInstructions)
            }
            
            return nestedRouteInstructions
        }
    }
    
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("反向地理編碼失敗: \(error.localizedDescription)")
                completion(nil, nil)
            } else if let placemark = placemarks?.first {
                // 使用 administrativeArea 來獲取縣市，locality 或 subLocality 來獲取區域
                let city = placemark.administrativeArea ?? "未知縣市"  // 縣市
                let district = placemark.locality ?? placemark.subLocality ?? "未知區"  // 行政區
                
                completion(city, district)
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



extension EstablishViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip
        if let currentLocation = locationManager.currentLocation?.coordinate {
            calculateTotalRouteTimeAndDetails(from: currentLocation, places: matchingPlaces) { [weak self] totalTravelTime, nestedInstructions in
                guard let self = self else { return }
                
                if let totalTravelTime = totalTravelTime, let nestedInstructions = nestedInstructions {
                    tripDetailVC.totalTravelTime = totalTravelTime // 傳遞總交通時間
                    tripDetailVC.nestedInstructions = nestedInstructions // 傳遞嵌套的導航指令數列
                }
                
                // 跳轉到 TripDetailViewController
                self.navigationController?.pushViewController(tripDetailVC, animated: true)
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
            make.top.equalTo(recommendRandomTripView.snp.bottom).offset(20)
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
        
        //        TODO: cell另外做
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? StyleTableViewCell {
            // 在這裡執行你要對 cell 的操作
            selectionTitle = cell.titleLabel.text ?? "" // 改變 cell 的背景顏色
            styleTag = Int(indexPath.row)
            styleLabel.text = selectionTitle
            styleLabel.textColor = .deepBlue
            styleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            
        }
    }
}
