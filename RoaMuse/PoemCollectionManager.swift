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
    
    var poemIdsInCollectionTrip = [String]()
    
    func addPoemId(_ id: String) {
        if !poemIdsInCollectionTrip.contains(id) {
            poemIdsInCollectionTrip.append(id)
        }
    }
    
    func isPoemAlreadyInCollection(_ id: String) -> Bool {
        return poemIdsInCollectionTrip.contains(id)
    }

    func loadPoemIdsFromFirebase(forUserId userId: String, completion: @escaping () -> Void) {
        poemIdsInCollectionTrip.removeAll()
        let userRef = FirebaseManager.shared.db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error loading user bookmarkTrip: \(error.localizedDescription)")
                completion()
                return
            }
            
            let bookmarkTripIds = document?.data()?["bookmarkTrip"] as? [String] ?? []
            
            guard !bookmarkTripIds.isEmpty else {
                print("No bookmarkTrip data found or it's empty.")
                completion()
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            for tripId in bookmarkTripIds {
                dispatchGroup.enter()
                
                FirebaseManager.shared.loadTripById(tripId) { trip in
                    if let trip = trip {
                        self.addPoemId(trip.poemId)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
}
