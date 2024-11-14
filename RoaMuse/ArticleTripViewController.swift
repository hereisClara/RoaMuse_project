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

class ArticleTripViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var nlpModel: poemLocationNLP3?
    
    var tripId = String()
    var poemId = String()
    var postUsernameLabel = UILabel()
    var poemTitleLabel = UILabel()
    let transportTimeLabel = UILabel()
    var placeLabel = UILabel()
    var searchRadius: CLLocationDistance = 15000
    var mapView = MKMapView()
    let db = Firestore.firestore()
    var annotations = [MKPointAnnotation]()
    var placePoemPairs = [PlacePoemPair]()
    var locationManager = LocationManager()
    var userLocation: CLLocationCoordinate2D?
    let activityIndicator = GradientActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    var containerView = UIView()
    let generateView = UIView()
    let generateTitleLabel = UILabel()
    let generateIcon = UIImageView()
    var transportType: MKDirectionsTransportType = .automobile
    var placeNames = [String]()
    
    let arrowButton = UIButton(type: .custom)
    var matchingPlaces: [(keyword: String, place: Place)] = []
    var places: [Place] = []
    var keywordToLineMap = [String: String]()
    var city: String = ""
    var districts: [String] = []
    var popUpView = PopUpView()
    var trip: Trip?
    var postTrip: Trip?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        
        guard !tripId.isEmpty else { return }
        generateView.isUserInteractionEnabled = false
        popUpView.delegate = self
        setupContainerView()
        setupGenerateView()
        setupMapView()
        loadPlacesDataAndAnnotateMap()
        checkIfTripBookmarked()
        
        view.addSubview(activityIndicator)
        setupActivityIndicator()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.nlpModel = try poemLocationNLP3(configuration: .init())
                DispatchQueue.main.async {
                    self.generateView.isUserInteractionEnabled = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.generateView.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    func setupActivityIndicator() {
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        
        activityIndicator.isHidden = true
    }
    
    @objc func didTapGenerateView() {
        guard let _ = self.nlpModel else { return }
        generateView.isUserInteractionEnabled = false
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            generateView.isUserInteractionEnabled = true
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
        
        locationManager.onLocationUpdate = { [weak self] currentLocation in
                    guard let self = self else { return }
                    self.locationManager.stopUpdatingLocation()
                    self.locationManager.onLocationUpdate = nil
                    self.processWithCurrentLocation(currentLocation)
                }
    }
    
    func processWithCurrentLocation(_ currentLocation: CLLocation) {
        print("process")
        FirebaseManager.shared.loadPoemById(self.poemId) { poem in
            if poem.content.isEmpty {
                print("content empty")
                DispatchQueue.main.async {
                    self.generateView.isUserInteractionEnabled = true
                }
                return
            }
            print("content not empty")
            let timeoutWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.showNoPlacesFoundAlert()
                    self.generateView.isUserInteractionEnabled = true
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeoutWorkItem)

            self.processPoemText(poem.content.joined(separator: "\n")) { keywords, keywordToLineMap in
                timeoutWorkItem.cancel()
                print("Timeout Work Item cancelled: \(timeoutWorkItem.isCancelled)")
                self.keywordToLineMap = keywordToLineMap
                self.generateTripFromKeywords(keywords, poem: poem, startingFrom: currentLocation) { trip in
                    if let trip = trip {
                        let places = self.matchingPlaces.map { $0.place }
                        self.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: places) { _, _ in
                            DispatchQueue.main.async {
                                self.popUpView.showPopup(on: self.view, with: trip, city: self.city, districts: self.districts)
                                self.trip = trip
                                self.generateView.isUserInteractionEnabled = true
                                self.activityIndicator.stopAnimating()
                                self.activityIndicator.isHidden = true
                            }
                            //MARK: city is nil
                            print("!!!!!   ", self.city)
                            FirebaseManager.shared.saveCityToTrip(tripId: trip.id, poemId: poem.id, city: self.city) { error in
                                if let error = error {
                                    print("Error saving data: \(error.localizedDescription)")
                                } else {
                                    print("Data saved successfully")
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.generateView.isUserInteractionEnabled = true
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.isHidden = true
                        }
                    }
                }
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
            let searchRadius: Double = 10000

            for keyword in keywords {
                dispatchGroup.enter()
                self.processKeywordPlaces(keyword: keyword, currentLocation: currentLocation) { validPlaceFound in
                    if validPlaceFound {
                        foundValidPlace = true
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
                if foundValidPlace, self.matchingPlaces.count >= 1 {
                    self.saveTripToFirebase(poem: poem) { trip in
                        print("saveTripToFirebase")
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

    func processKeywordPlaces(keyword: String, currentLocation: CLLocation, completion: @escaping (Bool) -> Void) {
        FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
            let nearbyPlaces = places.filter { place in
                let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                let distance = currentLocation.distance(from: placeLocation)
                return distance <= self.searchRadius
            }

            if let randomPlace = nearbyPlaces.randomElement() {
                if !self.matchingPlaces.contains(where: { $0.place.id == randomPlace.id }) {
                    self.matchingPlaces.append((keyword: keyword, place: randomPlace))
                }

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
                    completion(true)
                }
            } else {
                // 使用 PlaceDataManager 搜索地點
                PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces, hasFoundPlace in
                    if hasFoundPlace == false {
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
    
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first {
                let city = placemark.administrativeArea
                let cityName = cityCodeMapping[city ?? ""]
                let district = placemark.subLocality
                completion(city, district)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func showNoPlacesFoundAlert() {
        let alert = UIAlertController(title: "提示", message: "未找到符合條件的地點", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func processPoemText(_ inputText: String, completion: @escaping ([String], [String: String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let maxSegments = 5
            let textSegments = inputText.components(separatedBy: CharacterSet.newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .prefix(maxSegments)
            
            guard let model = try? poemLocationNLP3(configuration: .init()) else {
                DispatchQueue.main.async {
                    completion([], [:])
                }
                return
            }
            
            var allResults = [String]()
            var keywordToLineMap = [String: String]()
            for segment in textSegments {
                do {
                    let prediction = try model.prediction(text: segment)
                    let landscape = prediction.label
                    allResults.append(landscape)
                    keywordToLineMap[landscape] = segment
                    print(allResults)
                } catch {
                    print("分析失敗：\(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                completion(Array(Set(allResults)), keywordToLineMap)
            }
        }
    }
    
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
                var documentRef: DocumentReference?
                documentRef = db.collection("trips").addDocument(data: tripData) { error in
                    if let error = error {
                        completion(nil)
                    } else {
                        guard let documentID = documentRef?.documentID else {
                            completion(nil)
                            return
                        }
                        
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
                                
                                self.getPoemPlacePair()
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

extension ArticleTripViewController {
    @objc func didTapCollectButton() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        
        FirebaseManager.shared.loadTripById(tripId) { trip in
            
            self.postTrip = trip
            guard let postTrip = self.postTrip else {
                print("trip無值")
                return
            }
            
            self.popUpView.showPopup(on: self.view, with: postTrip, city: nil, districts: nil)
        }
    }
}

extension ArticleTripViewController {
    
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
        mapView.showsCompass = true
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .blue  // 路線顏色
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PlaceMarker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if annotation is MKUserLocation {
            return nil
        }
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.pinTintColor = .red
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        self.userLocation = userLocation.coordinate
    }
    
    func checkIfTripBookmarked() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { [weak self] (document, _) in
            guard let self = self else { return }
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    if let bookmarkTrips = document.data()?["bookmarkTrip"] as? [String] {
                        self.arrowButton.isSelected = bookmarkTrips.contains(self.tripId)
                        self.arrowButton.tintColor = self.arrowButton.isSelected ? .systemBlue : .white
                    }
                }
            } else {
                print("無法獲取用戶資料")
            }
        }
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
    
    func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: startLocation)
        let destinationPlacemark = MKPlacemark(coordinate: endLocation)
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        directions.calculate { response, _ in
            if let route = response?.routes.first {
                completion(route)
            } else {
                completion(nil)
            }
        }
    }
    
    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [Place], completion: @escaping (TimeInterval?, [String]?) -> Void) {
        var totalTime: TimeInterval = 0
        let dispatchGroup = DispatchGroup()
        var placeOrder = [String]()
        
        if let firstPlace = places.first {
            let firstPlaceLocation = CLLocationCoordinate2D(latitude: firstPlace.latitude, longitude: firstPlace.longitude)
            dispatchGroup.enter()
            calculateRoute(from: currentLocation, to: firstPlaceLocation) { route in
                if let route = route {
                    totalTime += route.expectedTravelTime
                    self.mapView.addOverlay(route.polyline)
                    placeOrder.append(firstPlace.name)
                }
                dispatchGroup.leave()
            }
        } else {
            completion(nil, nil)
            return
        }
        
        if places.count >= 2 {
            for index in 0..<(places.count - 1) {
                let startPlace = places[index]
                let endPlace = places[index + 1]
                
                let startLocation = CLLocationCoordinate2D(latitude: startPlace.latitude, longitude: startPlace.longitude)
                let endLocation = CLLocationCoordinate2D(latitude: endPlace.latitude, longitude: endPlace.longitude)
                
                dispatchGroup.enter()
                calculateRoute(from: startLocation, to: endLocation) { route in
                    if let route = route {
                        totalTime += route.expectedTravelTime
                        DispatchQueue.main.async {
                            self.mapView.addOverlay(route.polyline)
                        }
                        placeOrder.append(endPlace.name)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(totalTime, placeOrder)
        }
    }
}

extension ArticleTripViewController {
    
    private func getPoemPlacePair() {
        placePoemPairs.removeAll()
        for matchingPlace in matchingPlaces {
            let keyword = matchingPlace.keyword
            if let poemLine = keywordToLineMap[keyword] {
                let placePoemPair = PlacePoemPair(placeId: matchingPlace.place.id, poemLine: poemLine)
                placePoemPairs.append(placePoemPair)
            }
        }
    }
    
    private func saveSimplePlacePoemPairsToFirebase(tripId: String, simplePairs: [PlacePoemPair], completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let tripRef = db.collection("trips").document(tripId)
        
        let placePoemData = simplePairs.map { pair in
            return [
                "placeId": pair.placeId,
                "poemLine": pair.poemLine
            ] as [String: Any]
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
}

extension ArticleTripViewController {
    
    func setupContainerView() {
        view.addSubview(containerView)
        containerView.layer.borderColor = UIColor.deepBlue.cgColor
        containerView.layer.borderWidth = 2.5
        containerView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(view).multipliedBy(0.72)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        containerView.layer.cornerRadius = 15
        
        arrowButton.setImage(UIImage(named: "right-arrow"), for: .normal)
        arrowButton.tintColor = .deepBlue
        arrowButton.addTarget(self, action: #selector(didTapCollectButton), for: .touchUpInside)
        
        containerView.addSubview(postUsernameLabel)
        postUsernameLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(12)
            make.leading.equalTo(containerView).offset(15)
        }
        postUsernameLabel.textColor = .deepBlue
        postUsernameLabel.font = UIFont(name: "NotoSerifHK-Black", size: 26)
        
        containerView.addSubview(arrowButton)
        arrowButton.snp.makeConstraints { make in
            make.centerY.equalTo(postUsernameLabel)
            make.trailing.equalTo(containerView).offset(-15)
            make.width.height.equalTo(30)
        }
        
        containerView.addSubview(poemTitleLabel)
        poemTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(postUsernameLabel)
            make.top.equalTo(postUsernameLabel.snp.bottom).offset(8)
        }
        poemTitleLabel.textColor = .deepBlue
        poemTitleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        
        containerView.addSubview(placeLabel)
        placeLabel.snp.makeConstraints { make in
            make.top.equalTo(poemTitleLabel.snp.bottom).offset(24)
            make.leading.equalTo(postUsernameLabel)
        }
        placeLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 14)
        placeLabel.textColor = .forBronze
        displayPlacesInLabel()
        
        containerView.addSubview(transportTimeLabel)
        transportTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(poemTitleLabel)
            make.top.equalTo(placeLabel.snp.bottom).offset(8)
        }
        transportTimeLabel.textColor = .forBronze
        transportTimeLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
    }
    
    func setupGenerateView() {
        
        view.addSubview(generateView)
        generateView.backgroundColor = .deepBlue
        generateView.layer.cornerRadius = 20
        generateView.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(view).multipliedBy(0.08)
            make.top.equalTo(containerView.snp.bottom).offset(16)
        }
        
        generateView.addSubview(generateTitleLabel)
        generateTitleLabel.text = "生成屬於你的旅程"
        generateTitleLabel.textColor = .white
        generateTitleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        generateTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(generateView)
            make.leading.equalTo(generateView).offset(15)
        }
        
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
        
        print("~~~~~", self.postTrip)
        
        guard let postTrip = self.postTrip else {
            print("Error: Trip is nil!")
            return
        }
        
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = postTrip
        tripDetailVC.keywordToLineMap = self.keywordToLineMap
        
        FirebaseManager.shared.loadPlacesByIds(placeIds: postTrip.placeIds) { [weak self] places in
            guard let self = self else { return }
            if let currentLocation = self.userLocation {
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

extension ArticleTripViewController {
    
    func loadPlacesDataAndAnnotateMap() {
        let tripRef = Firestore.firestore().collection("trips").document(tripId)
        tripRef.getDocument { (document, _) in
            if let document = document, document.exists {
                if let placeIds = document.data()?["placeIds"] as? [String] {
                    print("Place IDs: \(placeIds)")
                    let dispatchGroup = DispatchGroup()
                    
                    for placeId in placeIds {
                        dispatchGroup.enter()
                        self.loadPlaceData(placeId: placeId) {
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self.mapView.showAnnotations(self.annotations, animated: true)
                        print("=====", self.userLocation)
                        if let userLocation = self.userLocation {
                            print("正在调用 calculateTotalRouteTimeAndDetails")
                            self.calculateTotalRouteTimeAndDetails(from: userLocation, places: self.places) { totalTime, placeOrder in
                                print("in")
                                if let totalTime = totalTime {
                                    self.updateTransportTimeLabel(totalTime: totalTime)
                                }
                                if let placeOrder = placeOrder {
                                    self.placeNames = placeOrder
                                    self.displayPlacesInLabel()
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
    
    func loadPlaceData(placeId: String, completion: @escaping () -> Void) {
        let placeRef = Firestore.firestore().collection("places").document(placeId)
        placeRef.getDocument { (document, _) in
            if let document = document, document.exists {
                if let latitude = document.data()?["latitude"] as? Double,
                   let longitude = document.data()?["longitude"] as? Double,
                   let name = document.data()?["name"] as? String {
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    annotation.title = name
                    
                    self.mapView.addAnnotation(annotation)
                    self.annotations.append(annotation)
                    let place = Place(id: placeId, name: name, latitude: latitude, longitude: longitude)
                    self.places.append(place)
                    completion()
                }
            } else {
                print("Place data not found for placeId: \(placeId)")
                completion()
            }
        }
    }
}
