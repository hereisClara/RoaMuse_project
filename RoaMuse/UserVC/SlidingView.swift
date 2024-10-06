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
    var isExpanded: Bool = false
    
    init(frame: CGRect, parentViewController: UIViewController) {
            self.parentViewController = parentViewController
            super.init(frame: frame)
            setupUI()
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.backgroundColor = .backgroundGray
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(MapTripTableViewCell.self, forCellReuseIdentifier: "TripIdCell")
        tableView.register(PhotoCollectionTableViewCell.self, forCellReuseIdentifier: "CollectionTableViewCell")
        addSubview(tableView)
        
        // 使用 SnapKit 設置 tableView 的約束
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(15)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }
}

extension SlidingView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = UIView()
            headerView.backgroundColor = .backgroundGray
            
            let titleLabel = UILabel()
            titleLabel.text = "旅行記憶"
            titleLabel.textColor = .deepBlue
            titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 28)
            
            let showMoreButton = UIButton(type: .system)
            showMoreButton.setTitle("查看更多", for: .normal)
            showMoreButton.addTarget(self, action: #selector(handleShowMoreTapped), for: .touchUpInside)
            
            headerView.addSubview(showMoreButton)
            headerView.addSubview(titleLabel)
            
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalTo(headerView)
                make.leading.equalTo(headerView).offset(16)
            }
            
            showMoreButton.snp.makeConstraints { make in
                make.trailing.equalTo(headerView).offset(-16)
                make.centerY.equalTo(headerView)
            }
            
            if isExpanded == false {
                showMoreButton.isHidden = false
            } else {
                showMoreButton.isHidden = true
            }
            
            return headerView
        } else {
            
            let headerView = UIView()
            headerView.backgroundColor = .backgroundGray
            
            let titleLabel = UILabel()
            titleLabel.text = "時光印痕"
            titleLabel.textColor = .deepBlue
            titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 28)
            
            headerView.addSubview(titleLabel)
            
            titleLabel.snp.makeConstraints { make in
                make.centerY.equalTo(headerView)
                make.leading.equalTo(headerView).offset(16)
            }
            
            return headerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isExpanded || tripIds.count <= 3 {
                return tripIds.count
            } else {
                return 3 // 限制最多显示5行
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TripIdCell", for: indexPath) as? MapTripTableViewCell
            let tripId = tripIds[indexPath.row]
            
            cell?.selectionStyle = .none
            cell?.backgroundColor = .clear
            fetchPoemTitleAndPoemLine(tripId: tripId) { poemTitle, poemLine in
                DispatchQueue.main.async {
                    
                    cell?.titleLabel.text = poemTitle
                    cell?.poemLineLabel.text = poemLine
                }
            }
            
            return cell ?? UITableViewCell()
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionTableViewCell", for: indexPath) as? PhotoCollectionTableViewCell
            cell?.backgroundColor = .clear
            cell?.updateImages(images)  // 更新圖片
            cell?.parentViewController = self.parentViewController
            return cell ?? UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100  // tripId 的 cell 高度
        } else {
            guard !images.isEmpty else {
                return 0
            }

            let numberOfRows = ceil(Double(images.count) / 3.0)
            let totalHeight = numberOfRows * 100.0 + (numberOfRows - 1) * 10.0
            
            return max(totalHeight, 0)
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
    
    @objc func handleShowMoreTapped() {
        isExpanded = true
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

}
