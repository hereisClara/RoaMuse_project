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
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.title = "建立"
        
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.deepBlue // 修改為你想要的顏色
            ]
        
        view.backgroundColor = UIColor(resource: .backgroundGray)
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
        
        recommendRandomTripView.layer.cornerRadius = 20
        
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
        FirebaseManager.shared.loadTripsByTag(tag: styleTag) { [weak self] trips in
            guard let self = self else { return }

            print("正在查詢 tag 值: \(self.styleTag)")  // 調試用
            if !trips.isEmpty {
                guard let randomTrip = trips.randomElement() else {
                    print("無法隨機選取行程") // 調試
                    return
                }

                print("成功選取行程: \(randomTrip.id)")  // 調試用

                self.randomTrip = randomTrip
                print("..........", randomTrip)

                self.popupView.showPopup(on: self.view, with: randomTrip)

                self.popupView.tapCollectButton = { [weak self] in
                    guard let self = self else { return }
                    guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }

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
        styleTableView.separatorStyle = .none
        
        view.addSubview(styleTableView)
        styleTableView.snp.makeConstraints { make in
            make.top.equalTo(recommendRandomTripView.snp.bottom).offset(20)
            make.width.equalTo(recommendRandomTripView)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.centerX.equalTo(view)
        }
        
        styleTableView.rowHeight = UITableView.automaticDimension
        styleTableView.estimatedRowHeight = 200
        styleTableView.backgroundColor = .clear
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
            styleLabel.textColor = .deepBlue
            styleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        }
    }
    
    func updatePlaceData(userId: String, trip: Trip, placeId: String) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var completedPlaces = document.data()?["completedPlace"] as? [[String: Any]],
                   var completedTrips = document.data()?["completedTrip"] as? [String] {
                    
                    if let index = completedPlaces.firstIndex(where: { $0["tripId"] as? String == trip.id }) {
                        var placeIds = completedPlaces[index]["placeIds"] as? [String] ?? []
                        if !placeIds.contains(placeId) {
                            placeIds.append(placeId)
                            completedPlaces[index]["placeIds"] = placeIds
                        }
                    } else {
                        completedPlaces.append(["tripId": trip.id, "placeIds": [placeId]])
                    }
                    
                    userRef.updateData(["completedPlace": completedPlaces]) { error in
                        if let error = error {
                            print("更新 completedPlace 失敗: \(error.localizedDescription)")
                        } else {
                            print("成功將地點 \(placeId) 添加到行程 \(trip.id) 的 completedPlace 中")
                        }
                    }
                    
                    let completedPlaceIds = completedPlaces.first(where: { $0["tripId"] as? String == trip.id })?["placeIds"] as? [String] ?? []
                    let allPlacesCompleted = trip.places.allSatisfy { place in
                        completedPlaceIds.contains(place.id)
                    }
                    
                    if allPlacesCompleted && !completedTrips.contains(trip.id) {
                        completedTrips.append(trip.id)
                        userRef.updateData(["completedTrip": completedTrips]) { error in
                            if let error = error {
                                print("更新 completedTrip 失敗: \(error.localizedDescription)")
                            } else {
                                print("成功將行程 \(trip.id) 添加到 completedTrip 中")
                            }
                        }
                    }
                    
                } else {
                    let newCompletedPlace = [["tripId": trip.id, "placeIds": [placeId]]]
                    let completedTrips = document.data()?["completedTrip"] as? [String] ?? []
                    let newCompletedTrip = completedTrips.contains(trip.id) ? completedTrips : completedTrips + [trip.id]
                    
                    userRef.updateData([
                        "completedPlace": newCompletedPlace,
                        "completedTrip": newCompletedTrip
                    ]) { error in
                        if let error = error {
                            print("初始化 completedPlace 或 completedTrip 失敗: \(error.localizedDescription)")
                        } else {
                            print("成功初始化 completedPlace，並添加地點 \(placeId) 和行程 \(trip.id)")
                        }
                    }
                }
            } else {
                print("無法找到用戶資料: \(error?.localizedDescription ?? "未知錯誤")")
            }
        }
    }
}
