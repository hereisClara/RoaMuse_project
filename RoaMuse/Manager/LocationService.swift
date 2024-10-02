import Foundation
import CoreLocation
import MapKit

class LocationService {
    
    // 單例模式
    static let shared = LocationService()
    
    private init() {}
    
    var matchingPlaces = [Place]()
    var city: String = ""
    var districts: [String] = []
    let searchRadius: Double = 15000
    
    // 反向地理編碼方法
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("反向地理編碼失敗: \(error.localizedDescription)")
                completion(nil, nil)
            } else if let placemark = placemarks?.first {
                let city = placemark.administrativeArea ?? "未知縣市"  // 縣市
                let district = placemark.locality ?? placemark.subLocality ?? "未知區"  // 行政區
                completion(city, district)
            } else {
                completion(nil, nil)
            }
        }
    }

    // 計算路徑的總時間和詳細信息
    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [Place], completion: @escaping (TimeInterval?, [MKRoute]?) -> Void) {
        var totalTime: TimeInterval = 0
        var routes = [MKRoute]()
        let dispatchGroup = DispatchGroup()
        
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
                    routes.append(route)
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

    // 計算單條路徑
    private func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, completion: @escaping (TimeInterval?, MKRoute?) -> Void) {
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

    // 處理詩詞文本並返回關鍵字列表
    func processPoemText(_ inputText: String, completion: @escaping ([String]) -> Void) {
        let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard let model = try? poemLocationNLP3(configuration: .init()) else {
            return
        }
        
        var allResults = [String]()
        for segment in textSegments {
            do {
                let prediction = try model.prediction(text: segment)
                let landscape = prediction.label
                allResults.append(landscape)
            } catch {
                print("Error processing poem text")
            }
        }
        completion(Array(Set(allResults))) // 去重並返回關鍵字
    }
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var foundValidPlace = false
        self.city = "" // 清空现有的城市
        self.districts.removeAll() // 清空现有的行政区
        self.matchingPlaces.removeAll()
        
        for keyword in keywords {
            dispatchGroup.enter()
            processKeywordPlaces(keyword: keyword, currentLocation: currentLocation, dispatchGroup: dispatchGroup) { validPlaceFound in
                if validPlaceFound {
                    foundValidPlace = true
                }
                // dispatchGroup.leave() 已在 processKeywordPlaces 内部调用
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if foundValidPlace, self.matchingPlaces.count >= 1 {
                FirebaseManager.shared.saveTripToFirebase(poem: poem, matchingPlaces: self.matchingPlaces) { trip in
                    completion(trip)
                }
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
                return distance <= self.searchRadius // 示例半径，您可以根据需要调整
            }

            if !nearbyPlaces.isEmpty {
                if let randomPlace = nearbyPlaces.randomElement() {
                    if !self.matchingPlaces.contains(where: { $0.id == randomPlace.id }) {
                        self.matchingPlaces.append(randomPlace)

                        let placeLocation = CLLocation(latitude: randomPlace.latitude, longitude: randomPlace.longitude)
                        self.reverseGeocodeLocation(placeLocation) { (city, district) in
                            if let city = city, let district = district {
                                if self.city.isEmpty {
                                    self.city = city
                                }
                                if !self.districts.contains(district) {
                                    self.districts.append(district)
                                }
                            }
                            completion(true)
                            dispatchGroup.leave() // 在此处调用 dispatchGroup.leave()
                        }
                    } else {
                        completion(true)
                        dispatchGroup.leave() // 如果地点已存在，立即调用 completion 和 dispatchGroup.leave()
                    }
                } else {
                    completion(false)
                    dispatchGroup.leave()
                }
            } else {
                // 如果在 Firebase 中没有找到符合条件的地点，尝试从 Google Maps API 搜索
                PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                    if let newPlace = foundPlaces.first {
                        PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                            if let savedPlace = savedPlace {
                                self.matchingPlaces.append(savedPlace)
                                self.reverseGeocodeLocation(CLLocation(latitude: savedPlace.latitude, longitude: savedPlace.longitude)) { (city, district) in
                                    if let city = city, let district = district {
                                        if self.city.isEmpty {
                                            self.city = city
                                        }
                                        if !self.districts.contains(district) {
                                            self.districts.append(district)
                                        }
                                    }
                                    completion(true)
                                    dispatchGroup.leave() // 在此处调用 dispatchGroup.leave()
                                }
                            } else {
                                completion(false)
                                dispatchGroup.leave()
                            }
                        }
                    } else {
                        completion(false)
                        dispatchGroup.leave()
                    }
                }
            }
        }
    }

    // 創建嵌套導航指令數列
    func createNestedRouteInstructions(routesArray: [[MKRoute]]) -> [[[String: Any]]] {
        var nestedRouteInstructions = [[[String: Any]]]()
        
        for routeArray in routesArray {
            var stepInstructions = [[String: Any]]()
            if let route = routeArray.first {
                for step in route.steps {
                    let stepData: [String: Any] = [
                        "instructions": step.instructions,
                        "distance": step.distance,
                        "notice": step.notice ?? "無通知"
                    ]
                    stepInstructions.append(stepData)
                }
            }
            nestedRouteInstructions.append(stepInstructions)
        }
        
        return nestedRouteInstructions
    }
}
