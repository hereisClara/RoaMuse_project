//
//  SlidingView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import UIKit
import FirebaseFirestore

class SlidingView: UIView {
    
    weak var parentViewController: UIViewController?

    var tripIds: [String] = []  // tripId 數據源
    var images: [UIImage] = []  // 圖片數據源
    var tableView: UITableView!
    var currentPlaceId: String?
    
    init(frame: CGRect, parentViewController: UIViewController) {
            self.parentViewController = parentViewController
            super.init(frame: frame)
            setupUI()
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        
        // 設置 tableView
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TripIdCell")
        tableView.register(CollectionTableViewCell.self, forCellReuseIdentifier: "CollectionTableViewCell")
        addSubview(tableView)
        
        // 使用 SnapKit 設置 tableView 的約束
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
    }
}

extension SlidingView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2  // 第一個 section 顯示 tripId，第二個 section 顯示 collectionView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return tripIds.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // 這裡處理 tripId 的 cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "TripIdCell", for: indexPath)
            let tripId = tripIds[indexPath.row]
            
            cell.selectionStyle = .none
            // 使用 tripId 去 Firestore 中查找對應的詩的名字
            fetchPoemTitleAndPoemLine(tripId: tripId) { poemTitle, poemLine in
                DispatchQueue.main.async {
                    // 在 cell 的 textLabel 中顯示詩名
                    cell.textLabel?.text = poemTitle
                    
                    cell.detailTextLabel?.text = poemLine
                    print("===", poemLine)
                }
            }
            
            return cell
        } else {
            // 這裡處理 collectionView 的 cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionTableViewCell", for: indexPath) as? CollectionTableViewCell
            cell?.updateImages(images)  // 更新圖片
            return cell ?? UITableViewCell()
        }
    }
    
    // 設置每個 section 的高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80  // tripId 的 cell 高度
        } else {
            return 140  // 包含 collectionView 的 cell 高度
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {

            let selectedTripId = tripIds[indexPath.row]
            
            FirebaseManager.shared.loadTripById(selectedTripId) { selectedTrip in
                DispatchQueue.main.async {
                    guard let trip = selectedTrip else {
                        print("無法獲取 trip 資料")
                        return
                    }
                    print("naviii")
                    self.navigateToTripDetailPage(selectedTrip: trip)
                }
            }
        }
    }
    
    func navigateToTripDetailPage(selectedTrip: Trip?) {
            guard let parentVC = self.parentViewController else {
                print("無法獲取當前的視圖控制器")
                return
            }

            let tripDetailVC = TripDetailViewController()
            tripDetailVC.trip = selectedTrip
            parentVC.navigationController?.pushViewController(tripDetailVC, animated: true)
        }
    
    func fetchPoemTitleAndPoemLine(tripId: String, completion: @escaping (String, String) -> Void) {
        let tripsRef = Firestore.firestore().collection("trips").document(tripId)
        
        tripsRef.getDocument { document, error in
            if let error = error {
                print("獲取行程資料失敗: \(error.localizedDescription)")
                completion("無詩名", "無詩句")
                return
            }
            
            guard let tripData = document?.data(),
                  let poemId = tripData["poemId"] as? String,
                  let placePoemPairs = tripData["placePoemPairs"] as? [[String: Any]] else {
                completion("無詩名", "無詩句")
                return
            }
            
            // 通過 poemId 查找詩名
            let poemsRef = Firestore.firestore().collection("poems").document(poemId)
            
            poemsRef.getDocument { poemDocument, error in
                if let error = error {
                    print("獲取詩資料失敗: \(error.localizedDescription)")
                    completion("無詩名", "無詩句")
                    return
                }
                
                let poemTitle = poemDocument?.get("title") as? String ?? "無詩名"
                
                // 查找 placeId 對應的詩句
                var matchingPoemLine = "無詩句"
                for pair in placePoemPairs {
                    if let placeId = pair["placeId"] as? String,
                       placeId == self.currentPlaceId, // 假設你有一個當前的 placeId
                       let poemLine = pair["poemLine"] as? String {
                        matchingPoemLine = poemLine
                        break
                    }
                }
                
                completion(poemTitle, matchingPoemLine)
            }
        }
    }
}
