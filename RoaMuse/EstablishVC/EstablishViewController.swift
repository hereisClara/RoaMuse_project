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
    
    var poemsFromFirebase: [[String: Any]] = []
    var fittingPoemArray = [[String: Any]]()
    
    private let recommendRandomTripView = UIView()
    private let styleTableView = UITableView()
    private let styleLabel = UILabel()
    private var selectionTitle = String()
    private var styleTag = Int()
    private let popupView = PopUpView()
    let locationManager = LocationManager()
    
//    private var randomTrip: Trip?
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
        print("tap")
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
    
    @objc func randomTripEntryButtonDidTapped() {
        print("random")
//       TODO: 篩選tag
        // 定義當位置更新時的回調
        locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            
            // Step 2: 獲取隨機詩詞
            FirebaseManager.shared.loadAllPoems { poems in
                if let randomPoem = poems.randomElement() {
                    print(randomPoem)
                    // Step 3: 利用 NLP 模型分析詩詞關鍵字
                    self.processPoemText(randomPoem.content.joined(separator: "\n")) { keywords in
                        // Step 4: 基於關鍵字排出行程
                        self.generateTripFromKeywords(keywords, poem: randomPoem, startingFrom: currentLocation) { trip in
                            DispatchQueue.main.async {
                                // Step 5: 顯示生成的行程，包含行程類別等資訊
                                self.popupView.showPopup(on: self.view, with: trip)
                            }
                        }
                    }
                }
            }
        }

        // 啟動位置更新
        locationManager.startUpdatingLocation()
    }

    // 基於 NLP 模型分析詩詞
    func processPoemText(_ inputText: String, completion: @escaping ([String]) -> Void) {
        let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard let model = try? poemLocationNLP3(configuration: .init()) else {
            print("NLP 模型加載失敗")
            return
        }

        var allResults = [String]()
        for segment in textSegments {
            do {
                let prediction = try model.prediction(text: segment)
                let landscape = prediction.label
                allResults.append(landscape)
                
            } catch {
                print("分析失敗：\(error.localizedDescription)")
            }
        }
        print(Array(Set(allResults)))
        completion(Array(Set(allResults))) // 去重並返回關鍵字
    }

    // 基於關鍵字生成行程
    func generateTripFromKeywords(_ keywords: [String], poem: Poem, startingFrom currentLocation: CLLocation, completion: @escaping (Trip) -> Void) {
        var matchingPlaces = [Place]()
        
        let dispatchGroup = DispatchGroup()

        // 遍歷每個關鍵字並從 Firebase 中查找相應的地點
        for keyword in keywords {
            dispatchGroup.enter()
            FirebaseManager.shared.loadPlacesByKeyword(keyword: keyword) { places in
                if places.isEmpty {
                    // 如果 Firebase 沒有找到地點，呼叫 Google Places API，使用當前位置
                    PlaceDataManager.shared.searchPlaces(withKeywords: [keyword], startingFrom: currentLocation) { foundPlaces in
                        print("搜尋到的地點數量：\(foundPlaces.count)") // 印出搜尋到的地點數量
                        if let newPlace = foundPlaces.first {
                            print("第一個地點名稱：\(newPlace.name), 經緯度：\(newPlace.latitude), \(newPlace.longitude)") // 印出第一個找到的地點
                            // 保存新的地點到 Firebase
                            PlaceDataManager.shared.savePlaceToFirebase(newPlace) { savedPlace in
                                if let savedPlace = savedPlace {
                                    print("成功保存地點：\(savedPlace.name)")
                                    matchingPlaces.append(savedPlace)
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            print("未找到符合的地點")
                            dispatchGroup.leave()
                        }
                    }

                } else {
                    matchingPlaces.append(contentsOf: places)
                    dispatchGroup.leave()
                }
            }
        }

        // 當所有地點查詢完成後，生成行程
        dispatchGroup.notify(queue: .main) {
            if matchingPlaces.count >= 3 {
                let trip = Trip(
                    poemId: poem.id,
                    id: UUID().uuidString,
                    placeIds: matchingPlaces.map { $0.id },
                    tag: poem.tag,
                    season: nil,   // 暫時不處理季節
                    weather: nil,  // 暫時不處理天氣
                    startTime: nil // 暫時不處理開始時間
                )
                completion(trip)
            } else {
                print("沒有足夠的地點來生成行程")
            }
        }
    }
    // 根据关键词生成行程的类别标签
    func determineTripTag(from keywords: [String]) -> Int {
        // 这里你可以根据关键词逻辑来判断属于哪一类行程，返回对应的类别标签
        if keywords.contains("海灘") {
            return 1 // 例如：海灘類行程
        } else if keywords.contains("山") {
            return 2 // 山區類行程
        } else {
            return 0 // 默認類型
        }
    }

    
}

extension EstablishViewController: PopupViewDelegate {
    
    func navigateToTripDetailPage() {
        let tripDetailVC = TripDetailViewController()
//        tripDetailVC.trip = randomTrip
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
}
