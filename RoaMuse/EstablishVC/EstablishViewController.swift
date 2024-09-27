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
    
    
    private let recommendRandomTripView = UIView()
    private let styleTableView = UITableView()
    private let styleLabel = UILabel()
    private var selectionTitle = String()
    private var styleTag = Int()
    private let popupView = PopUpView()
    let locationManager = LocationManager()
    
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
        //       TODO: 篩選tag
        // 定義當位置更新時的回調
        locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            
            // Step 2: 獲取隨機詩詞
            FirebaseManager.shared.loadAllPoems { poems in
                if let randomPoem = poems.randomElement() {
                    print(randomPoem)
                    // Step 3: 利用 NLP 模型分析詩詞關鍵字
                    self.processPoemText(randomPoem.content.joined(separator: "\n")) { keywords in
                        // Step 4: 基於關鍵字排出行程
                        self.generateTripFromKeywords(keywords, poem: randomPoem, startingFrom: currentLocation) { trip in
                            
                            if let trip = trip {
                                // 使用 placeIds 計算交通時間
                                self.calculateTotalRouteTimeAndDetails(from: currentLocation.coordinate, places: self.matchingPlaces) { totalTravelTime, routes in
                                    if let totalTravelTime = totalTravelTime {
                                        let totalMinutes = Int(totalTravelTime / 60)
                                        print("總預估交通時間：\(totalMinutes) 分鐘")
                                        
                                        // 你可以在這裡使用 totalTravelTime 或 totalMinutes 做進一步處理
                                    }
                                }
                            }
                            
                            DispatchQueue.main.async {
                                // Step 5: 顯示生成的行程，包含行程類別等資訊
                                guard let trip = trip else { return }
                                self.popupView.showPopup(on: self.view, with: trip)
                            }
                        }
                    }
                }
            }
        }
        
        // 啟動位置更新
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
    
//    TODO: 先判斷資料庫地點有沒有在範圍內的，如果沒有，才去打api
    
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        
        let dispatchGroup = DispatchGroup()
        var foundValidPlace = false  // 用來標記是否找到符合條件的有效地點
        
        // 遍歷每個關鍵字並從 Firebase 中查找相應的地點
        for keyword in keywords {
            dispatchGroup.enter()
            FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
                if places.isEmpty {
                    
                    PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                        print("搜尋到的地點數量：\(foundPlaces.count)")
                        if let newPlace = foundPlaces.first {
                            print("第一個地點名稱：\(newPlace.name), 經緯度：\(newPlace.latitude), \(newPlace.longitude)")
                            PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                                if let savedPlace = savedPlace {
                                    print("成功保存地點：\(savedPlace.name)")
                                    self.matchingPlaces.append(savedPlace)
                                    foundValidPlace = true
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            print("未找到符合的地點")
                            dispatchGroup.leave()
                        }
                    }
                } else {
                    self.matchingPlaces.append(contentsOf: places)
                    foundValidPlace = true
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if foundValidPlace, self.matchingPlaces.count >= 1 {  // 只有找到有效地點才生成行程
                let tripData: [String: Any] = [
                    "poemId": poem.id,
                    "placeIds": self.matchingPlaces.map { $0.id },
                    "tag": poem.tag
                ]
                
                let db = Firestore.firestore()
                var documentRef: DocumentReference? = nil
                documentRef = db.collection("trips").addDocument(data: tripData) { error in
                    if let error = error {
                        print("Error saving trip to Firebase: \(error)")
                        completion(nil)
                    } else {
                        guard let documentID = documentRef?.documentID else {
                            print("未能獲取到 documentID")
                            completion(nil)
                            return
                        }
                        print("成功保存行程，ID: \(documentID)")
                        
                        let trip = Trip(
                            poemId: poem.id,
                            id: documentID,
                            placeIds: self.matchingPlaces.map { $0.id },
                            tag: poem.tag,
                            season: nil,   // 暫時不處理季節
                            weather: nil,  // 暫時不處理天氣
                            startTime: nil // 暫時不處理開始時間
                        )
                        completion(trip)
                    }
                }
            } else {
                print("沒有找到符合條件的有效地點，無法生成行程")
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
}

extension EstablishViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
//        tripDetailVC.trip = randomTrip
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
