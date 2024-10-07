//
//  PlaceDataManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/26.
//

import Foundation
import CoreLocation
import FirebaseFirestore

class PlaceDataManager {
    
    static let shared = PlaceDataManager()
    private let apiKey: String
    
    private init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let googlePlacesAPIKey = config["GOOGLE_PLACES_API_KEY"] as? String {
            self.apiKey = googlePlacesAPIKey
            print("~~~", self.apiKey)
        } else {
            self.apiKey = ""  // 如果金鑰未設置，設置為空字符串（需要處理錯誤情況）
            print("Google Places API Key is missing!")
        }
    }
    
    func searchPlaces(withKeywords keywords: [String], startingFrom startLocation: CLLocation, completion: @escaping ([Place]) -> Void) {
        var foundPlaces = [Place]()
        var currentLocation = startLocation
        let dispatchGroup = DispatchGroup()
        
        // 遞迴搜尋地點
        func searchNextKeyword(index: Int) {
            if index >= keywords.count {
                completion(foundPlaces)
                return
            }
            
            var keyword = keywords[index]
            let radius = 15000  // 搜索半徑，單位為公尺
            var typeRestrictions = "park|natural_feature"  // 限制搜尋類型為公園或自然景點
            
            if keyword == "山" {
                keyword = "高山 登山"  // 使用更具體的關鍵字
                typeRestrictions = "hiking_trail|mountain|natural_feature"  // 限制搜尋高山或登山步道類型
            }
            
            dispatchGroup.enter()
            searchPlaceByKeyword(keyword, location: currentLocation, radius: radius, typeRestrictions: typeRestrictions) { [weak self] place in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }
                
                if let place = place {
                    // 檢查 placeId 是否已經存在，避免重複
                    if !foundPlaces.contains(where: { $0.id == place.id }) {
                        foundPlaces.append(place)
                        currentLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                    } else {
                        print("Place with ID \(place.id) already exists, skipping.")
                    }
                }
                
                dispatchGroup.leave()
                searchNextKeyword(index: index + 1)
            }
        }
        
        searchNextKeyword(index: 0)
    }

    func searchPlaceByKeyword(_ keyword: String, location: CLLocation, radius: Int, typeRestrictions: String, completion: @escaping (Place?) -> Void) {
        let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        let locationParam = "location=\(location.coordinate.latitude),\(location.coordinate.longitude)"
        let radiusParam = "&radius=\(radius)"
        let keywordParam = "&keyword=\(keyword)"
        let typeParam = "&type=\(typeRestrictions)"
        let apiKeyParam = "&key=\(apiKey)"
        
        let urlString = baseURL + locationParam + radiusParam + keywordParam + typeParam + apiKeyParam
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching places: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    
                    let filteredPlaces = results.filter { place in
                        let userRatingsTotal = place["user_ratings_total"] as? Int ?? 0
                        let rating = place["rating"] as? Double ?? 0.0
                        return userRatingsTotal > 100 || rating > 3.5
                    }
                    
                    if let firstPlace = filteredPlaces.first {
                        let place = self.parsePlace(from: firstPlace)
                        completion(place)
                    } else {
                        print("未找到符合條件的地點")
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(nil)
            }
        }.resume()
    }

    // 解析 Google Places API 回應中的地點資料
    func parsePlace(from dictionary: [String: Any]) -> Place? {
        guard let name = dictionary["name"] as? String,
              let geometry = dictionary["geometry"] as? [String: Any],
              let location = geometry["location"] as? [String: Any],
              let lat = location["lat"] as? Double,
              let lng = location["lng"] as? Double,
              let placeId = dictionary["place_id"] as? String else {
            return nil
        }
        
        return Place(id: placeId, name: name, latitude: lat, longitude: lng)
    }
//    TODO: 處理重複上傳問題
    // 保存地點到 Firebase
    func savePlaceToFirebase(_ place: Place, completion: @escaping (Place?) -> Void) {
        let db = Firestore.firestore()

        // 四捨五入經緯度來限制精度，避免微小的差異導致重複上傳
        let roundedLatitude = round(place.latitude * 10000) / 10000
        let roundedLongitude = round(place.longitude * 10000) / 10000

        // 先檢查 Firebase 中是否已經有相同名稱和相近經緯度的地點
        let placeRef = db.collection("places")
            .whereField("latitude", isEqualTo: roundedLatitude)
            .whereField("longitude", isEqualTo: roundedLongitude)
            .whereField("name", isEqualTo: place.name)

        placeRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error checking for existing place: \(error)")
                completion(nil)
                return
            }
            
            // 如果找到相同的地點，則不進行上傳
            if let snapshot = snapshot, !snapshot.isEmpty {
                print("Place already exists in Firebase, skipping upload.")
                if let document = snapshot.documents.first {
                    var placeToUpdate = place
                    placeToUpdate.id = document.documentID  // Update the id to Firebase's documentID
                    completion(placeToUpdate)  // Return the updated place
                } else {
                    completion(nil)
                }
                return
            }
            
            var placeToUpdate = place
            
            let placeData: [String: Any] = [
                "name": place.name,
                "latitude": roundedLatitude,
                "longitude": roundedLongitude
            ]

            var documentRef: DocumentReference? = nil

            // 保存 place 到 Firebase
            documentRef = db.collection("places").addDocument(data: placeData) { error in
                if let error = error {
                    print("Error saving place to Firebase: \(error)")
                    completion(nil)
                } else {
                    print("Successfully saved place: \(place.name)")

                    // 使用 Firebase 自動生成的 documentID 更新 place 的 id
                    guard let documentID = documentRef?.documentID else {
                        completion(nil)
                        return
                    }

                    // 更新 documentID 到 Firebase 中的 id 字段
                    documentRef?.updateData(["id": documentID]) { error in
                        if let error = error {
                            print("Error updating place id: \(error)")
                            completion(nil)
                        } else {
                            // 更新 place 對象的 id
                            placeToUpdate.id = documentID
                            print("Updated place ID: \(placeToUpdate.id)")
                            completion(placeToUpdate)  // 返回更新後的 place
                        }
                    }
                }
            }
        }
    }

}

