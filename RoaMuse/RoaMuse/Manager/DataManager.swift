//
//  DataManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

import Foundation

class DataManager {
    
    var trips: [Trip] = []
    var places: [Place] = []
    static let shared = DataManager()
    
    // 定義一個方法來讀取本地 JSON 檔案
    func loadJSONData() {
        // 找到專案中的 JSON 檔案路徑
        if let filePath = Bundle.main.path(forResource: "data", ofType: "json") {
            do {
                // 讀取 JSON 檔案內容
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                
                // 在解析前，打印 JSON 原始內容以確認讀取是否正確
                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("讀取到的 JSON: \(jsonString)")
                }
                
                // 使用 JSONDecoder 將資料解析為 Trip 結構
                let decoder = JSONDecoder()
                let json = try decoder.decode(Json.self, from: data)
                
                // 在這裡可以使用 trip 資料
                for trip in json.trips {
                    trips.append(trip)
                }
            } catch {
                print("讀取或解析 JSON 時發生錯誤: \(error)")
            }
        } else {
            print("無法找到 JSON 檔案")
        }
    }

    func loadPlacesJSONData() {
        // 找到專案中的 JSON 檔案路徑
        if let filePath = Bundle.main.path(forResource: "PlaceData", ofType: "json") {
            do {
                // 讀取 JSON 檔案內容
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                
                // 在解析前，打印 JSON 原始內容以確認讀取是否正確
                if let jsonString = String(data: data, encoding: .utf8) {
//                    print("讀取到的 JSON: \(jsonString)")
                }
                
                // 使用 JSONDecoder 將資料解析為 Trip 結構
                let decoder = JSONDecoder()
                let json = try decoder.decode(PlaceJson.self, from: data)
                
                // 在這裡可以使用 trip 資料
                for place in json.places {
//                    print("成功解析 Trip: \(place)")
//                    print(place)
                    places.append(place)
                }
            } catch {
                print("讀取或解析 JSON 時發生錯誤: \(error)")
            }
        } else {
            print("無法找到 JSON 檔案")
        }
    }
}
