//
//  PoemMatchingService.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/3.
//

import Foundation
import FirebaseFirestore

class PoemMatchingService {

    func findBestMatchedPoem(currentSeason: Int, currentWeather: Int, currentTime: Int, completion: @escaping (Poem?, Double?) -> Void) {
        let db = Firestore.firestore()
        
        let seasonProximityMatrix: [[Double]] = [
            [1.0, 1.0, 1.0, 1.0, 1.0],
            [0.8, 1.0, 0.4, 0.2, 0.0],
            [0.8, 0.4, 1.0, 0.4, 0.2],
            [0.8, 0.2, 0.4, 1.0, 0.2],
            [0.8, 0.0, 0.2, 0.4, 1.0]
        ]
        
        let timeProximityMatrix: [[Double]] = [
            [1.0, 1.0, 1.0, 1.0],
            [0.8, 1.0, 0.3, 0.0],
            [0.8, 0.3, 1.0, 0.3],
            [0.8, 0.0, 0.3, 1.0]
        ]
        
        let totalScore: Double = 100.0
        let perConditionScore = totalScore / 3.0
        
        db.collection("poems").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching poems: \(error)")
                completion(nil, nil)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion(nil, nil)
                return
            }
            
            var bestMatchingScore: Double = 0.0
            var bestMatchedPoem: Poem?
            
            for document in documents {
                let data = document.data()
                guard let poemSeason = data["season"] as? Int,
                      let poemWeather = data["weather"] as? Int,
                      let poemTime = data["time"] as? Int else {
                    continue
                }
                
                var matchingScore: Double = 0.0
                matchingScore += seasonProximityMatrix[currentSeason][poemSeason] * perConditionScore
                if currentWeather == poemWeather || poemWeather == 0 {
                    matchingScore += perConditionScore
                }
                matchingScore += timeProximityMatrix[currentTime][poemTime] * perConditionScore
                
                if matchingScore > bestMatchingScore {
                    bestMatchingScore = matchingScore
                    bestMatchedPoem = Poem(
                        id: data["id"] as? String ?? "",
                        title: data["title"] as? String ?? "",
                        poetry: data["poetry"] as? String ?? "",
                        content: data["content"] as? [String] ?? [],
                        tag: data["tag"] as? Int ?? 0,
                        season: data["season"] as? Int,
                        weather: data["weather"] as? Int,
                        time: data["time"] as? Int
                    )
                }
            }
            
            let bestMatchingPercentage = round((bestMatchingScore / totalScore) * 100)
            completion(bestMatchedPoem, bestMatchingPercentage)
        }
    }
}
