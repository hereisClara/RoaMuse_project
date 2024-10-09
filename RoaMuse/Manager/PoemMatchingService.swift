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
    
    func getCurrentSeason() -> Int {
            let month = Calendar.current.component(.month, from: Date())
            switch month {
            case 3...5:
                return 1 // 春天
            case 6...8:
                return 2 // 夏天
            case 9...11:
                return 3 // 秋天
            default:
                return 4 // 冬天
            }
        }
        
        // 獲取當前時間
        func getCurrentTimeOfDay() -> Int {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5...11:
                return 1 // 白天
            case 12...17:
                return 2 // 傍晚
            case 18...23, 0...4:
                return 3 // 晚上
            default:
                return 0 // 不限
            }
        }
        
    func getSeasonAndTimeText(completion: @escaping (String) -> Void) {
            let currentSeason = getCurrentSeason()
            let currentTimeOfDay = getCurrentTimeOfDay()
            
            var seasonText = ""
            var timeText = ""
            
            // 根據季節設置文本
            switch currentSeason {
            case 1:
                seasonText = "春日"
            case 2:
                seasonText = "夏日"
            case 3:
                seasonText = "秋季"
            case 4:
                seasonText = "冬季"
            default:
                seasonText = ""
            }
            
            // 根據時間設置文本
            switch currentTimeOfDay {
            case 1:
                timeText = "日頭正好"
            case 2:
                timeText = "夕照之時"
            case 3:
                timeText = "夜色無邊"
            default:
                timeText = ""
            }
            
            // 組合最終顯示的文字
            let finalText = "\(seasonText)、\(timeText)"
            
            // 回调返回組合的文本
            completion(finalText)
        }
}
