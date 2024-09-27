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
    
    //    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "建立"
        
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.deepBlue // 修改為你想要的顏色
        ]
        
        view.backgroundColor = UIColor(resource: .backgroundGray)
        view.backgroundColor = UIColor(resource: .backgroundGray)
        styleTableView.register(StyleTableViewCell.self, forCellReuseIdentifier: "styleCell")
        
        popupView.delegate = self
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        
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
        print("tap")
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
            // 結束刷新
            self.styleTableView.mj_header?.endRefreshing()
        }
    }
    
    @objc func randomTripEntryButtonDidTapped() {
        // 禁用按鈕防止重複點擊
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
                    print(randomPoem)
                    
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
    
    // 在保存行程前，檢查 Firebase 中是否已存在相同的行程
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var foundValidPlace = false
         // 10公里
        
        self.city = "" // 清空現有的城市
        self.districts.removeAll() // 清空現有的行政區
        self.matchingPlaces.removeAll()
        
        for keyword in keywords {
            dispatchGroup.enter()

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
                    foundValidPlace = true
                    dispatchGroup.leave()
                } else {
                    PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                        if let newPlace = foundPlaces.first {
                            PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                                if let savedPlace = savedPlace {
                                    self.matchingPlaces.append(savedPlace)
                                    foundValidPlace = true
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            
            
            if foundValidPlace, self.matchingPlaces.count >= 1 {
                let tripData: [String: Any] = [
                    "poemId": poem.id,
                    "placeIds": self.matchingPlaces.map { $0.id },
                    "tag": poem.tag
                ]
                
                // 保存前先檢查是否有相同的行程
                FirebaseManager.shared.checkTripExists(tripData) { exists in
                    if exists {
                        let existingTrip = Trip(
                            poemId: poem.id,
                            id: "existing_trip_id",  // 可以用一個占位符表示現有行程
                            placeIds: self.matchingPlaces.map { $0.id },
                            tag: poem.tag,
                            season: nil,
                            weather: nil,
                            startTime: nil
                        )
                        
                        // 調用 popup 顯示現有行程
                        DispatchQueue.main.async {
                            self.popupView.showPopup(on: self.view, with: existingTrip, city: self.city, districts: self.districts)
                        }
                        
                        // 調用 completion 並傳回存在的行程
                        completion(existingTrip)
                    } else {
                        // 行程不存在，進行保存
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
            } else {
                completion(nil)
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
    
    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [Place], completion: @escaping (TimeInterval?, [MKRoute]?) -> Void) {
        var totalTime: TimeInterval = 0
        var routes = [MKRoute]()  // 用來存放每段路線的詳細資訊
        let dispatchGroup = DispatchGroup()
        
        // 確保有地點可供計算
        guard !places.isEmpty else {
            print("沒有地點可供計算")
            completion(nil, nil)
            return
        }
        
        totalTime = 0
        routes.removeAll()
        
        
        // Step 1: 計算從當前位置到第一個地點的時間
        if let firstPlace = places.first {
            let firstPlaceLocation = CLLocationCoordinate2D(latitude: firstPlace.latitude, longitude: firstPlace.longitude)
            
            dispatchGroup.enter()
            calculateRoute(from: currentLocation, to: firstPlaceLocation) { travelTime, route in
                if let travelTime = travelTime, let route = route {
                    totalTime += travelTime
                    routes.append(route)  // 保存路線資訊
                    print("從當前位置到第一個地點的時間：\(travelTime) 秒")
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
                        routes.append(route)
                        print("從地點 \(num) 到地點 \(num + 1) 的時間：\(travelTime) 秒")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // Step 3: 返回總時間和詳細路線
        dispatchGroup.notify(queue: .main) {
            print("總交通時間：\(totalTime) 秒")
            completion(totalTime, routes)
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
}

extension EstablishViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip
        navigationController?.pushViewController(tripDetailVC, animated: true)
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
