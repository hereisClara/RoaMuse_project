import Foundation
import CoreLocation
import MapKit

class LocationService {
    
    static let shared = LocationService()
    
    init() {}
    
    var matchingPlaces = [(keyword: String, place: Place)]()
    var city: String = ""
    var districts: [String] = []
    let searchRadius: Double = 15000
    
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("反向地理編碼失败: \(error.localizedDescription)")
                completion(nil, nil)
            } else if let placemark = placemarks?.first {
                let city = placemark.administrativeArea ?? "未知縣市"
                let district = placemark.locality ?? placemark.subLocality ?? "未知行政區"
                completion(city, district)
            } else {
                completion(nil, nil)
            }
        }
    }

    func calculateTotalRouteTimeAndDetails(from currentLocation: CLLocationCoordinate2D, places: [Place], completion: @escaping (TimeInterval?, [MKRoute]?) -> Void) {
        var totalTime: TimeInterval = 0
        var routes = [MKRoute]()
        let dispatchGroup = DispatchGroup()
        
        guard !places.isEmpty else {
            print("没有地點可供計算")
            completion(nil, nil)
            return
        }
        
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
        
        if places.count > 1 {
            for num in 0..<(places.count - 1) {
                let startLocation = CLLocationCoordinate2D(latitude: places[num].latitude, longitude: places[num].longitude)
                let endLocation = CLLocationCoordinate2D(latitude: places[num + 1].latitude, longitude: places[num + 1].longitude)
                
                dispatchGroup.enter()
                calculateRoute(from: startLocation, to: endLocation) { travelTime, route in
                    if let travelTime = travelTime, let route = route {
                        totalTime += travelTime
                        routes.append(route)
                        print("从地點 \(num) 到地點 \(num + 1) 的時間：\(travelTime) 秒")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("總交通時間：\(totalTime) 秒")
            completion(totalTime, routes)
        }
    }

    private func calculateRoute(from startLocation: CLLocationCoordinate2D, to endLocation: CLLocationCoordinate2D, completion: @escaping (TimeInterval?, MKRoute?) -> Void) {
        let request = MKDirections.Request()
        
        let sourcePlacemark = MKPlacemark(coordinate: startLocation)
        let destinationPlacemark = MKPlacemark(coordinate: endLocation)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        
        request.transportType = .automobile
        
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
        self.city = ""
        self.districts.removeAll()
        self.matchingPlaces.removeAll()
        
        for keyword in keywords {
            dispatchGroup.enter()
            processKeywordPlaces(keyword: keyword, currentLocation: currentLocation, dispatchGroup: dispatchGroup) { validPlaceFound in
                if validPlaceFound {
                    foundValidPlace = true
                }
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
                        completion(true)
                        dispatchGroup.leave()
                    }
                } else {
                    completion(false)
                    dispatchGroup.leave()
                }
            } else {
                PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces, _  in
                    print("從 Google API 找到的地點: \(foundPlaces)")
                    if let newPlace = foundPlaces.first {
                        PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                            if let savedPlace = savedPlace {
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
