import Foundation
import CoreLocation
import MapKit

class LocationService {
    
    // 单例模式
    static let shared = LocationService()
    
    init() {}
    
    var matchingPlaces = [(keyword: String, place: Place)]()
    var city: String = ""
    var districts: [String] = []
    let searchRadius: Double = 15000
    
    // 反向地理编码方法
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("反向地理编码失败: \(error.localizedDescription)")
                completion(nil, nil)
            } else if let placemark = placemarks?.first {
                let city = placemark.administrativeArea ?? "未知县市"  // 县市
                let district = placemark.locality ?? placemark.subLocality ?? "未知区"  // 行政区
                completion(city, district)
            } else {
                completion(nil, nil)
            }
        }
    }

    // 计算路径的总时间和详细信息
    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [Place], completion: @escaping (TimeInterval?, [MKRoute]?) -> Void) {
        var totalTime: TimeInterval = 0
        var routes = [MKRoute]()
        let dispatchGroup = DispatchGroup()
        
        guard !places.isEmpty else {
            print("没有地点可供计算")
            completion(nil, nil)
            return
        }
        
        // Step 1: 计算从当前位置到第一个地点的时间
        if let firstPlace = places.first {
            let firstPlaceLocation = CLLocationCoordinate2D(latitude: firstPlace.latitude, longitude: firstPlace.longitude)
            
            dispatchGroup.enter()
            calculateRoute(from: currentLocation, to: firstPlaceLocation) { travelTime, route in
                if let travelTime = travelTime, let route = route {
                    totalTime += travelTime
                    routes.append(route)
                    print("从当前位置到第一个地点的时间：\(travelTime) 秒")
                }
                dispatchGroup.leave()
            }
        }
        
        // Step 2: 计算地点之间的时间
        if places.count > 1 {
            for num in 0..<(places.count - 1) {
                let startLocation = CLLocationCoordinate2D(latitude: places[num].latitude, longitude: places[num].longitude)
                let endLocation = CLLocationCoordinate2D(latitude: places[num + 1].latitude, longitude: places[num + 1].longitude)
                
                dispatchGroup.enter()
                calculateRoute(from: startLocation, to: endLocation) { travelTime, route in
                    if let travelTime = travelTime, let route = route {
                        totalTime += travelTime
                        routes.append(route)
                        print("从地点 \(num) 到地点 \(num + 1) 的时间：\(travelTime) 秒")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // Step 3: 返回总时间和详细路线
        dispatchGroup.notify(queue: .main) {
            print("总交通时间：\(totalTime) 秒")
            completion(totalTime, routes)
        }
    }

    // 计算单条路径
    private func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, completion: @escaping (TimeInterval?, MKRoute?) -> Void) {
        let request = MKDirections.Request()
        
        let sourcePlacemark = MKPlacemark(coordinate: startLocation)
        let destinationPlacemark = MKPlacemark(coordinate: endLocation)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        
        request.transportType = .automobile  // 或者 .walking
        
        // 计算路线
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

    // 处理诗词文本并返回关键字列表
    func processPoemText(_ inputText: String, completion: @escaping ([String], [String: String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard let model = try? poemLocationNLP3(configuration: .init()) else {
                print("NLP 模型加载失败")
                return
            }
            
            var allResults = [String]()
            var keywordToLineMap = [String: String]()
            
            for segment in textSegments {
                do {
                    let prediction = try model.prediction(text: segment)
                    let keyword = prediction.label
                    allResults.append(keyword)
                    keywordToLineMap[keyword] = segment
                } catch {
                    print("分析失败：\(error.localizedDescription)")
                }
            }
            DispatchQueue.main.async {
                completion(Array(Set(allResults)), keywordToLineMap)
            }
        }
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
        
        dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            if foundValidPlace, self.matchingPlaces.count >= 1 {
                print("matchingPlaces: \(self.matchingPlaces)")
                FirebaseManager.shared.saveTripToFirebase(poem: poem, matchingPlaces: self.matchingPlaces) { trip in
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

    func processKeywordPlaces(keyword: String, currentLocation: CLLocation, dispatchGroup: DispatchGroup, completion: @escaping (Bool) -> Void) {
        FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
            let nearbyPlaces = places.filter { place in
                let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                let distance = currentLocation.distance(from: placeLocation)
                return distance <= self.searchRadius
            }

            if let randomPlace = nearbyPlaces.randomElement() {
                print("随机选择的地点: \(randomPlace)")
                if !self.matchingPlaces.contains(where: { $0.place.id == randomPlace.id }) {
                    print("将地点加入 matchingPlaces: \(randomPlace)")
                    self.matchingPlaces.append((keyword: keyword, place: randomPlace))
                    print("当前 matchingPlaces: \(self.matchingPlaces)")
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
                        dispatchGroup.leave()
                    }
                } else {
                    completion(false)
                    dispatchGroup.leave()
                }
            } else {
                // 如果没有找到符合条件的地点，搜索并保存
                PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                    print("从 Google API 找到的地点: \(foundPlaces)")
                    if let newPlace = foundPlaces.first {
                        PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                            if let savedPlace = savedPlace {
                                // 确保不重复添加地点
                                if !self.matchingPlaces.contains(where: { $0.place.id == savedPlace.id }) {
                                    self.matchingPlaces.append((keyword: keyword, place: savedPlace))
                                    print("Matching places after adding: \(self.matchingPlaces)")
                                }
                                completion(true)
                            } else {
                                completion(false)
                            }
                            dispatchGroup.leave()
                        }
                    } else {
                        completion(false)
                        dispatchGroup.leave()
                    }
                }
            }
        }
    }

    // 创建嵌套导航指令数组
    func createNestedRouteInstructions(routesArray: [MKRoute]) -> [[[String: Any]]] {
        var nestedRouteInstructions = [[[String: Any]]]()
        
        for route in routesArray {
            var stepInstructions = [[String: Any]]()
            for step in route.steps {
                let stepData: [String: Any] = [
                    "instructions": step.instructions,
                    "distance": step.distance,
                    "notice": step.notice ?? "无通知"
                ]
                stepInstructions.append(stepData)
            }
            nestedRouteInstructions.append(stepInstructions)
        }
        
        return nestedRouteInstructions
    }
}
