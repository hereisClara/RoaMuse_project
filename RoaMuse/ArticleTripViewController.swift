//
//  ArticleTripViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/2.
//

import Foundation
import UIKit
import MapKit
import FirebaseFirestore

class ArticleTripViewController: UIViewController, MKMapViewDelegate {
    
    var tripId = String()
    var poemId = String()
    var postUsernameLabel = UILabel()
    var poemTitleLabel = UILabel()
    let transportTimeLabel = UILabel()
    var placeLabel = UILabel()
    
    var mapView = MKMapView()
    let db = Firestore.firestore()
    var annotations = [MKPointAnnotation]()
    var locationManager = LocationManager()
    var userLocation: CLLocationCoordinate2D?
    
    var containerView = UIView()
    let generateView = UIView()
    let generateTitleLabel = UILabel()
    let generateIcon = UIImageView()
    var transportType: MKDirectionsTransportType = .automobile
    var placeNames = [String]()
    
    let collectButton = UIButton(type: .custom)
    var matchingPlaces = [Place]()
    var city: String = ""
    var districts: [String] = []
    var popUpView = PopUpView()
    var trip: Trip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        guard !tripId.isEmpty else {
            return
        }
        
        popUpView.delegate = self
        
        setupContainerView()
        setupGenerateView()
        setupLocationManager()
        setupMapView()
        loadPlacesDataAndAnnotateMap()
        checkIfTripBookmarked()
    }
    
    
    
    @objc func didTapGenerateView() {
        // 禁用生成按鈕，避免重複點擊
        generateView.isUserInteractionEnabled = false
        
        // 開始更新位置，獲取當前使用者位置
        locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            
            // 停止位置更新，確保只獲取一次即可
            self.locationManager.stopUpdatingLocation()
            self.locationManager.onLocationUpdate = nil
            
            // 根據 poemId 查詢詩詞資料
            FirebaseManager.shared.loadPoemById(self.poemId) { poem in
                    self.generateView.isUserInteractionEnabled = true
                
                if poem.content.isEmpty {
                        print("未找到詩詞，內容為空")
                        return
                    }
                
                // 使用 NLP 模型解析詩詞，生成關鍵字
                self.processPoemText(poem.content.joined(separator: "\n")) { keywords in
                    guard !keywords.isEmpty else {
                            print("關鍵字生成失敗或無關鍵字")
                            self.generateView.isUserInteractionEnabled = true
                            return
                        }
                    // 使用關鍵字生成行程
                    self.generateTripFromKeywords(keywords, poem: poem, startingFrom: currentLocation) { trip in
                        guard let trip = trip else {
                                print("未生成行程，matchingPlaces 可能為空")
                                self.generateView.isUserInteractionEnabled = true
                                return
                            }
                        
                        let placeCoordinates = self.matchingPlaces.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                        
                        // 計算整體路線的總時間和詳細導航指令
                        self.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: placeCoordinates) { totalTime, routes in
                            if let totalTime = totalTime {
                                let totalMinutes = Int(totalTime / 60)
                                print("總預計交通時間：\(totalMinutes) 分鐘")
                            }
                            
                            self.popUpView.showPopup(on: self.view, with: trip, city: self.city, districts: self.districts)
                        }
                        
                        // 將生成的行程存儲，並解除按鈕的點擊鎖定
                        DispatchQueue.main.async {
                            self.trip = trip
                            self.generateView.isUserInteractionEnabled = true
                        }
                    }
                }
            }
        }
        locationManager.startUpdatingLocation()  // 開始獲取位置
    }

    func processPoemText(_ inputText: String, completion: @escaping ([String]) -> Void) {
        LocationService.shared.processPoemText(inputText, completion: completion)
    }

    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        LocationService.shared.generateTripFromKeywords(keywords, poem: poem, startingFrom: currentLocation, completion: completion)
    }

    
    func displayPlacesInLabel() {
        var placeDisplayText = ""
        print(placeNames)
        for (index, placeName) in placeNames.enumerated() {
            placeDisplayText += placeName
            if index < placeNames.count - 1 {
                placeDisplayText += " → "
            }
        }
        
        placeLabel.text = placeDisplayText
    }
    
    func updateTransportTimeLabel(totalTime: TimeInterval) {
        let minutes = Int(totalTime / 60)
        transportTimeLabel.text = "預計交通時間：\(minutes) 分鐘"
    }
    
    @objc func didTapCollectButton() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        if collectButton.isSelected {
            // 從 bookmarkTrip 中移除
            userRef.updateData([
                "bookmarkTrip": FieldValue.arrayRemove([tripId])
            ]) { error in
                if let error = error {
                    print("從 bookmarkTrip 中移除 tripId 時出錯: \(error.localizedDescription)")
                } else {
                    print("成功將 tripId 從 bookmarkTrip 中移除")
                }
            }
        } else {
            // 添加到 bookmarkTrip
            userRef.updateData([
                "bookmarkTrip": FieldValue.arrayUnion([tripId])
            ]) { error in
                if let error = error {
                    print("將 tripId 添加到 bookmarkTrip 中時出錯: \(error.localizedDescription)")
                } else {
                    print("成功將 tripId 添加到 bookmarkTrip 中")
                }
            }
        }
        
        collectButton.isSelected.toggle()
        collectButton.tintColor = collectButton.isSelected ? .systemBlue : .white
    }
    
    func checkIfTripBookmarked() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    if let bookmarkTrips = document.data()?["bookmarkTrip"] as? [String] {
                        self.collectButton.isSelected = bookmarkTrips.contains(self.tripId)
                        // 更新按鈕顏色
                        self.collectButton.tintColor = self.collectButton.isSelected ? .systemBlue : .white
                    }
                }
            } else {
                print("無法獲取用戶資料")
            }
        }
    }
    
    func setupMapView() {
        mapView.delegate = self
        containerView.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.width.equalTo(containerView).multipliedBy(0.95)
            make.height.equalTo(containerView).multipliedBy(0.65)
            make.bottom.equalTo(containerView).offset(-15)
        }
        mapView.layer.cornerRadius = 15
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    func setupLocationManager() {
        locationManager.onLocationUpdate = { [weak self] location in
            guard let self = self else { return }
            self.userLocation = location.coordinate  // 獲取當前使用者位置
            print("User location updated: \(location.coordinate)")
        }
        locationManager.startUpdatingLocation()
    }
    
    func loadPlacesDataAndAnnotateMap() {
        let tripRef = Firestore.firestore().collection("trips").document(tripId)
        tripRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let placeIds = document.data()?["placeIds"] as? [String] {
                    let dispatchGroup = DispatchGroup()
                    
                    // 遍歷每個 placeId，從 places 集合中加載對應的地點數據
                    for placeId in placeIds {
                        dispatchGroup.enter()
                        self.loadPlaceData(placeId: placeId) {
                            dispatchGroup.leave()
                        }
                    }
                    
                    // 當所有的地點數據加載完成後，調整地圖視角
                    dispatchGroup.notify(queue: .main) {
                        self.mapView.showAnnotations(self.annotations, animated: true)
                        
                        // 如果獲取到了使用者當前位置，則計算路線
                        if let userLocation = self.userLocation {
                            self.calculateTotalRouteTimeAndDetails(from: userLocation, places: self.annotations.map { annotation in
                                CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                            }) { totalTime, placeOrder in
                                if let totalTime = totalTime {
                                    self.updateTransportTimeLabel(totalTime: totalTime)
                                }
                                if let placeOrder = placeOrder {
                                    self.placeNames = placeOrder  // 更新 placeNames
                                    self.displayPlacesInLabel()  // 顯示地點
                                }
                            }
                        }
                    }
                }
            } else {
                print("Trip data not found")
            }
        }
    }
    
    // 加載每個 place 的經緯度並在地圖上標註
    func loadPlaceData(placeId: String, completion: @escaping () -> Void) {
        let placeRef = Firestore.firestore().collection("places").document(placeId)
        placeRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let latitude = document.data()?["latitude"] as? Double,
                   let longitude = document.data()?["longitude"] as? Double,
                   let name = document.data()?["name"] as? String {
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    annotation.title = name
                    
                    self.mapView.addAnnotation(annotation)
                    self.annotations.append(annotation)
                    
                    completion()
                }
            } else {
                print("Place data not found for placeId: \(placeId)")
                completion()
            }
        }
    }
    
    func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: startLocation)
        let destinationPlacemark = MKPlacemark(coordinate: endLocation)
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                completion(route)
            } else {
                completion(nil)
            }
        }
    }
    
    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [CLLocationCoordinate2D], completion: @escaping (TimeInterval?, [String]?) -> Void) {
        var totalTime: TimeInterval = 0
        let dispatchGroup = DispatchGroup()
        var placeOrder = [String]()  // 存放地點的順序
        
        // Step 1: 當前位置到第一個地點
        if let firstPlace = places.first {
                dispatchGroup.enter()
                calculateRoute(from: currentLocation, to: firstPlace) { route in
                    if let route = route {
                        totalTime += route.expectedTravelTime
                        self.mapView.addOverlay(route.polyline)  // 绘制路径
                        placeOrder.append(self.annotations.first?.title ?? "")
                    }
                    dispatchGroup.leave()
                }
            } else {
                // 如果没有任何地点，直接返回
                completion(nil, nil)
                return
            }
        
        // Step 2: 計算地點之間的路徑
        if places.count >= 2 {
                for index in 0..<(places.count - 1) {
                    let startLocation = places[index]
                    let endLocation = places[index + 1]
                    
                    dispatchGroup.enter()
                    calculateRoute(from: startLocation, to: endLocation) { route in
                        if let route = route {
                            totalTime += route.expectedTravelTime
                            self.mapView.addOverlay(route.polyline)  // 绘制每段路径
                            placeOrder.append(self.annotations[index + 1].title ?? "")
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        
        if places.isEmpty {
            let alert = UIAlertController(title: "提示", message: "附近沒有合適的地點", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            completion(nil, nil)
            return
        }
        
        // Step 3: 返回結果
        dispatchGroup.notify(queue: .main) {
            completion(totalTime, placeOrder)
        }
    }
}

extension ArticleTripViewController {
    
    // 繪製路線的覆蓋層
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .blue  // 路線顏色
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // 自定義地圖標註的視圖
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PlaceMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.pinTintColor = .red  // 自定義標註顏色
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
}

extension ArticleTripViewController {
    
    func setupContainerView() {
        view.addSubview(containerView)
        containerView.backgroundColor = .systemGray5
        containerView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(view).multipliedBy(0.6)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        containerView.layer.cornerRadius = 15
        
        collectButton.setImage(UIImage(named: "normal_bookmark"), for: .normal)
        collectButton.setImage(UIImage(named: "selected_bookmark"), for: .selected)
        collectButton.tintColor = .deepBlue
        collectButton.addTarget(self, action: #selector(didTapCollectButton), for: .touchUpInside)
        
        containerView.addSubview(postUsernameLabel)
        postUsernameLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(12)
            make.leading.equalTo(containerView).offset(15)
        }
        postUsernameLabel.textColor = .deepBlue
        postUsernameLabel.font = UIFont(name: "NotoSerifHK-Black", size: 30)
        
        containerView.addSubview(collectButton)
        collectButton.snp.makeConstraints { make in
            make.centerY.equalTo(postUsernameLabel)  // 與 postUsernameLabel 水平對齊
            make.trailing.equalTo(containerView).offset(-15)  // 放置在右側，距離右邊框 15
            make.width.height.equalTo(30)  // 設置按鈕大小
        }
        
        containerView.addSubview(poemTitleLabel)
        poemTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(postUsernameLabel)
            make.top.equalTo(postUsernameLabel.snp.bottom).offset(8)
        }
        poemTitleLabel.textColor = .deepBlue
        poemTitleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 20)
        
        containerView.addSubview(placeLabel)
        placeLabel.snp.makeConstraints { make in
            make.top.equalTo(poemTitleLabel.snp.bottom).offset(24)
            make.leading.equalTo(postUsernameLabel)
        }
        placeLabel.font = UIFont.systemFont(ofSize: 14, weight: .light)
        
        displayPlacesInLabel()
        
        containerView.addSubview(transportTimeLabel)
        transportTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(poemTitleLabel)
            make.top.equalTo(placeLabel.snp.bottom).offset(8)
        }
        transportTimeLabel.textColor = .gray
        transportTimeLabel.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setupGenerateView() {
        // 將 generateView 添加到主視圖中
        view.addSubview(generateView)
        generateView.backgroundColor = .deepBlue
        generateView.layer.cornerRadius = 15
        generateView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(80)
            make.top.equalTo(containerView.snp.bottom).offset(16)
        }
        
        // 設置標題
        generateView.addSubview(generateTitleLabel)
        generateTitleLabel.text = "生成屬於你的 \(poemTitleLabel.text ?? "")"
        generateTitleLabel.textColor = .white
        generateTitleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 20)
        generateTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(generateView)
            make.leading.equalTo(generateView).offset(15)
        }
        
        // 設置圖示
        generateView.addSubview(generateIcon)
        generateIcon.image = UIImage(systemName: "chevron.right.circle.fill")
        generateIcon.tintColor = .white
        generateIcon.snp.makeConstraints { make in
            make.centerY.equalTo(generateView)
            make.trailing.equalTo(generateView).offset(-15)
            make.width.height.equalTo(35)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapGenerateView))
        generateView.addGestureRecognizer(tapGesture)
    }
}

extension ArticleTripViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        
        guard let trip = self.trip else {
            print("Error: Trip is nil!")
            return
        }
        
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = trip

        FirebaseManager.shared.loadPlacesByIds(placeIds: trip.placeIds) { [weak self] places in
            guard let self = self else { return }
            
            if let currentLocation = self.locationManager.currentLocation?.coordinate {
                LocationService.shared.calculateTotalRouteTimeAndDetails(from: currentLocation, places: places) { totalTravelTime, routes in
                    if let totalTravelTime = totalTravelTime, let routes = routes {
                        tripDetailVC.totalTravelTime = totalTravelTime
                        var nestedInstructions = [[String]]()
                        for route in routes {
                            var stepInstructions = [String]()
                            for step in route.steps {
                                stepInstructions.append(step.instructions)
                            }
                            nestedInstructions.append(stepInstructions)
                        }
                        tripDetailVC.nestedInstructions = nestedInstructions
                    } else {
                        print("Failed to calculate routes or totalTravelTime.")
                    }

                    self.navigationController?.pushViewController(tripDetailVC, animated: true)
                }
            }
        }
    }

}
