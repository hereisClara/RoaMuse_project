//
//  PoemPostViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/9.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class PoemPostViewController: UIViewController {
    
    var allTripIds = [String]()
    var selectedPoem: Poem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.navigationItem.largeTitleDisplayMode = .never
        getCityToTrip()
        loadFilteredPosts(allTripIds: allTripIds) { filteredPosts in
            
        }
    }
    
    func loadFilteredPosts(allTripIds: [String], completion: @escaping ([[String: Any]]) -> Void) {
        
        FirebaseManager.shared.loadPosts { postsArray in
            // 獲取當前用戶 ID
            guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
                print("無法獲取當前用戶 ID")
                completion([])
                return
            }
            
            let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
            currentUserRef.getDocument { snapshot, error in
                if let error = error {
                    print("無法加載封鎖狀態: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let blockedUsers = snapshot?.data()?["blockedUsers"] as? [String] ?? []
                
                let filteredPosts = postsArray.compactMap { post -> [String: Any]? in
                    let postUserId = post["userId"] as? String ?? ""
                    if blockedUsers.contains(postUserId) {
                        return nil
                    }
                    return post
                }
                
                let tripFilteredPosts = filteredPosts.filter { post in
                    if let tripId = post["tripId"] as? String {
                        return allTripIds.contains(tripId)
                    }
                    return false
                }
                
                completion(tripFilteredPosts)
            }
        }
    }

    
    func getCityToTrip() {
        if let selectedPoem = selectedPoem {
            FirebaseManager.shared.getCityToTrip(poemId: selectedPoem.id) { poemsArray, error in
                if let error = error {
                    print("Error retrieving data: \(error.localizedDescription)")
                    return
                } else if let poemsArray = poemsArray {
                    
                    var cityGroupedPoems = [String: [[String: Any]]]()
                    
                    for poem in poemsArray {
                        if let city = poem["city"] as? String {
                            
                            if var existingPoems = cityGroupedPoems[city] {
                                existingPoems.append(poem)
                                cityGroupedPoems[city] = existingPoems
                            } else {
                                cityGroupedPoems[city] = [poem]
                            }
                        }
                    }
                    for (_, poems) in cityGroupedPoems {
                        for poem in poems {
                            if let tripId = poem["tripId"] as? String {
                                self.allTripIds.append(tripId)
                            }
                        }
                    }
                    print("City Grouped Poems: \(cityGroupedPoems)")
                }
            }
        }
    }
}
