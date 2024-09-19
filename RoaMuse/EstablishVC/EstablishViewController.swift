//
//  EstablishViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/12.
//

import UIKit
import SnapKit
import WeatherKit
import CoreLocation
import FirebaseFirestore
import MJRefresh

class EstablishViewController: UIViewController {
    
    private let recommendRandomTripView = UIView()
    private let styleTableView = UITableView()
    private let styleLabel = UILabel()
    private var selectionTitle = String()
    private var styleTag = Int()
    private let popupView = PopUpView()
    
    private var randomTrip: Trip?
    var postsArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "建立"
        view.backgroundColor = UIColor(resource: .backgroundGray)
        styleTableView.register(StyleTableViewCell.self, forCellReuseIdentifier: "styleCell")
        
        popupView.delegate = self
        
        setupUI()
        setupTableView()
        setupPullToRefresh()
        
    }
    
    func setupUI() {
        view.addSubview(recommendRandomTripView)
        recommendRandomTripView.addSubview(styleLabel)
        
        recommendRandomTripView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.9)
            make.height.equalTo(150)
        }
        
        styleLabel.snp.makeConstraints { make in
            make.center.equalTo(recommendRandomTripView)
        }
        
        styleLabel.font = UIFont.systemFont(ofSize: 24)
        
        recommendRandomTripView.backgroundColor = .white
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        recommendRandomTripView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        randomTripEntryButtonDidTapped()
    }
    
    func setupPullToRefresh() {
        styleTableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshData))
    }
    
    @objc func refreshData() {
        FirebaseManager.shared.loadNewPosts(existingPosts: self.postsArray) { newPosts in
            self.postsArray.insert(contentsOf: newPosts, at: 0)
            self.styleTableView.reloadData()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 結束刷新
            self.styleTableView.mj_header?.endRefreshing()
        }
    }
    
    func randomTripEntryButtonDidTapped() {
        // 根據選擇的 styleTag 從 Firebase 加載行程
        FirebaseManager.shared.loadTripsByTag(tag: styleTag) { [weak self] trips in
            guard let self = self else { return }

            print("正在查詢 tag 值: \(self.styleTag)")  // 調試用
            if !trips.isEmpty {
                // 隨機選擇一個行程
                guard let randomTrip = trips.randomElement() else {
                    print("無法隨機選取行程") // 調試
                    return
                }
                
                print("成功選取行程: \(randomTrip.id)")  // 調試用
                
                // 更新 randomTrip 變數，供後續使用
                self.randomTrip = randomTrip
                
                // 顯示彈出視窗，並傳入選中的行程
                self.popupView.showPopup(on: self.view, with: randomTrip)
                
                // 當點擊收藏按鈕時執行的操作
                self.popupView.tapCollectButton = { [weak self] in
                    guard let self = self else { return }
                    
                    FirebaseManager.shared.updateUserTripCollections(userId: userId, tripId: randomTrip.id) { success in
                        if success {
                            print("收藏行程成功！")
                        } else {
                            print("收藏行程失敗！")
                        }
                    }
                }
            } else {
                print("未找到符合的行程") // 調試用
            }
        }
    }

}

extension EstablishViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
        tripDetailVC.trip = randomTrip
        navigationController?.pushViewController(tripDetailVC, animated: true)
    }
}

extension EstablishViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        styleTableView.dataSource = self
        styleTableView.delegate = self
        
        view.addSubview(styleTableView)
        styleTableView.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView.snp.bottom).offset(10)
            make.width.equalTo(recommendRandomTripView)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalTo(view)
        }
        
        styleTableView.rowHeight = UITableView.automaticDimension
        styleTableView.estimatedRowHeight = 200
        styleTableView.backgroundColor = .orange
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = styleTableView.dequeueReusableCell(withIdentifier: "styleCell", for: indexPath) as? StyleTableViewCell
        
        cell?.titleLabel.text = styles[indexPath.row].name
        cell?.descriptionLabel.text = styles[indexPath.row].introduction
        cell?.selectionStyle = .none
        //        TODO: cell另外做
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? StyleTableViewCell {
            // 在這裡執行你要對 cell 的操作
            selectionTitle = cell.titleLabel.text ?? "" // 改變 cell 的背景顏色
            styleTag = Int(indexPath.row)
            styleLabel.text = selectionTitle
            
        }
    }
    
    func updatePlaceData(tripId: String, placeIndex: Int, placeId: String, isComplete: Bool) {
        let db = Firestore.firestore()
        
        // 指定 Firestore 中的文檔路徑
        let placePath = "trips/\(tripId)"
        
        // 構建要更新的字段數據
        let placeData: [String: Any] = [
            "places.\(placeIndex).id": placeId,
            "places.\(placeIndex).isComplete": isComplete
        ]
        
        // 更新 Firestore 中指定文檔的數據
        db.document(placePath).updateData(placeData) { error in
            if let error = error {
                print("更新失敗: \(error.localizedDescription)")
            } else {
                print("成功更新地點 \(placeId) 的資料")
            }
        }
    }
}
