//
//  PoemCollectionManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import FirebaseFirestore

class PoemCollectionManager {
    static let shared = PoemCollectionManager()
    
    private init() {}
    
    // 存儲已收藏的詩的id
    var poemIdsInCollectionTrip = [String]()
    
    // 添加詩id到收藏列表
    func addPoemId(_ id: String) {
        if !poemIdsInCollectionTrip.contains(id) {
            poemIdsInCollectionTrip.append(id)
        }
    }
    
    // 檢查詩是否已經存在於收藏列表中
    func isPoemAlreadyInCollection(_ id: String) -> Bool {
        return poemIdsInCollectionTrip.contains(id)
    }

    // 從 Firebase 加載用戶的 bookmarkTrip 對應的詩
    func loadPoemIdsFromFirebase(forUserId userId: String, completion: @escaping () -> Void) {
        // 先清空詩的id數組，避免重複添加
        poemIdsInCollectionTrip.removeAll()
        
        // 獲取 Firebase 中的用戶引用
        let userRef = FirebaseManager.shared.db.collection("users").document(userId)
        
        // 獲取 bookmarkTrip 數組
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error loading user bookmarkTrip: \(error.localizedDescription)")
                completion() // 发生错误时，依然调用 completion
                return
            }
            
            // 从用户数据中获取 bookmarkTrip，如果不存在，默认为空数组
            let bookmarkTripIds = document?.data()?["bookmarkTrip"] as? [String] ?? []
            
            // 如果 bookmarkTripIds 为空，直接调用 completion
            guard !bookmarkTripIds.isEmpty else {
                print("No bookmarkTrip data found or it's empty.")
                completion() // 如果是新用户或者没有收藏行程，直接完成
                return
            }
            
            // 遍歷 bookmarkTripIds，獲取每個 trip 對應的 poemId
            let dispatchGroup = DispatchGroup()
            
            for tripId in bookmarkTripIds {
                dispatchGroup.enter()
                
                // 根據 tripId 獲取行程，並提取對應的 poemId
                FirebaseManager.shared.loadTripById(tripId) { trip in
                    if let trip = trip {
                        // 添加詩的id到收藏列表
                        self.addPoemId(trip.poemId)
                    }
                    dispatchGroup.leave()
                }
            }
            
            // 當所有的 tripId 處理完後，調用 completion
            dispatchGroup.notify(queue: .main) {
                completion() // 完成數據加載後執行回調
            }
        }
    }
}
