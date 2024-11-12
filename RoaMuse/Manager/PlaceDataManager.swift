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
        } else {
            self.apiKey = ""
            print("Google Places API Key is missing!")
        }
    }
    
    func searchPlaces(withKeywords keywords: [String], startingFrom startLocation: CLLocation, radius: CLLocationDistance = 15000, completion: @escaping ([Place], Bool) -> Void) {
        var foundPlaces = [Place]()
        var currentLocation = startLocation
        let dispatchGroup = DispatchGroup()
        var hasFoundPlace = false
        
        func searchNextKeyword(index: Int) {
            if index >= keywords.count {
                completion(foundPlaces, hasFoundPlace)
                return
            }
            
            var keyword = keywords[index]
            let radius = radius
            var typeRestrictions = "park|natural_feature"
            
            if keyword == "山" {
                keyword = "高山 峰 嶺 步道"
                typeRestrictions = "hiking_trail|mountain|natural_feature"
            }
            
            dispatchGroup.enter()
            searchPlaceByKeyword(keyword, location: currentLocation, radius: Int(radius), typeRestrictions: typeRestrictions) { [weak self] place in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }
                
                if let place = place {
                    hasFoundPlace = true
                    if place.name.contains("協會") {
                        print("Skipping place with name containing 協會: \(place.name)")
                    } else {
                        if !foundPlaces.contains(where: { $0.id == place.id }) {
                            foundPlaces.append(place)
                            currentLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
                        } else {
                            print("Place with ID \(place.id) already exists, skipping.")
                        }
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
        
        URLSession.shared.dataTask(with: url) { data, _, error in
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

    func savePlaceToFirebase(_ place: Place, completion: @escaping (Place?) -> Void) {
        let db = Firestore.firestore()

        let roundedLatitude = round(place.latitude * 10000) / 10000
        let roundedLongitude = round(place.longitude * 10000) / 10000

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
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                print("Place already exists in Firebase, skipping upload.")
                if let document = snapshot.documents.first {
                    var placeToUpdate = place
                    placeToUpdate.id = document.documentID
                    completion(placeToUpdate) 
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

            var documentRef: DocumentReference?

            documentRef = db.collection("places").addDocument(data: placeData) { error in
                if let error = error {
                    print("Error saving place to Firebase: \(error)")
                    completion(nil)
                } else {
                    print("Successfully saved place: \(place.name)")

                    guard let documentID = documentRef?.documentID else {
                        completion(nil)
                        return
                    }

                    documentRef?.updateData(["id": documentID]) { error in
                        if let error = error {
                            print("Error updating place id: \(error)")
                            completion(nil)
                        } else {
                            placeToUpdate.id = documentID
                            print("Updated place ID: \(placeToUpdate.id)")
                            completion(placeToUpdate) 
                        }
                    }
                }
            }
        }
    }

}
