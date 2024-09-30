import UIKit
import SnapKit
import FirebaseFirestore

class AwardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var dynamicTaskSets: [[TaskSet]] = []
    let tableView = UITableView()
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    let awards = [
        ["踩點之路"], // 第 1 個 section
        ["浪漫大師", "奇險大師", "田園大師"],    // 第 2 個 section
        ["走到終點"]                   // 第 3 個 section
    ]
    
    let awardsDescription: [[String]] = [
        ["從開始到現在，一路走來，你已經走過了這麼多個地方⋯⋯"],
        ["在成為浪漫大師的路上", "在成為冒險者的路上", "在走向鄉野的路上"],
        ["有始有終，行萬卷書與你一起走過⋯⋯"]
    ]
    
    let awardSections = ["踩點總集", "風格master", "有始有終"]
    
        // 模擬的進度數據
        let progressValues: [[Float]] = [
            [0.8],   // 第 1 個 section
            [0.7, 0.6, 0.3],        // 第 2 個 section
            [0.9]              // 第 3 個 section
        ]
    
        var taskSets: [[TaskSet]] = [
            [TaskSet(totalTasks: 30, completedTasks: 30)],  // 第 1 个任务集合（cell）
            [TaskSet(totalTasks: 50, completedTasks: 50),
             TaskSet(totalTasks: 40, completedTasks: 40),
             TaskSet(totalTasks: 30, completedTasks: 30)],  // 第 2 个任务集合（cell）
            [TaskSet(totalTasks: 20, completedTasks: 20),
             TaskSet(totalTasks: 50, completedTasks: 50)]   // 第 3 个任务集合（cell）
        ]
    
    // 模擬的里程碑數據
    let milestones: [Float] = [0.3, 0.6, 1.0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        fetchUserData()
        // 設置 TableView
        setupTableView()
        setupTableViewHeader()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        
        // 註冊自定義的 UITableViewCell
        tableView.register(AwardTableViewCell.self, forCellReuseIdentifier: "awardCell")
        
        // 設置委託
        tableView.delegate = self
        tableView.dataSource = self
        
        // 使用 SnapKit 來設置 Auto Layout
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()  // 設置 tableView 與父視圖四周對齊
        }
    }
    
    func setupTableViewHeader() {
        let tableHeaderView = UIView()
        tableHeaderView.backgroundColor = .white
        
        let headerLabel = UILabel()
        headerLabel.text = "獎項進度總覽"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 32)
        headerLabel.textColor = .black
        
        tableHeaderView.addSubview(headerLabel)
        
        // 使用 SnapKit 設置 headerLabel 的 Auto Layout
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()  // 垂直居中
            make.leading.equalToSuperview().offset(16)  // 與左邊距離 16 點
        }
        
        // 設置表头的大小
        tableHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100)
        
        // 将 tableHeaderView 设为 TableView 的表头
        tableView.tableHeaderView = tableHeaderView
    }
    
    func fetchUserData() {
        // 假設 userId 是已經獲取的用戶 ID
        guard let userId = userId else {
            print("無法獲取 userId")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                print("獲取用戶數據時出錯: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, let data = document.data() else {
                print("無法解析用戶數據")
                return
            }
            
            // 計算 completedPlace 中 placeIds 的總數
            var totalPlacesCompleted = 0
            if let completedPlace = data["completedPlace"] as? [[String: Any]] {
                for placeEntry in completedPlace {
                    if let placeIds = placeEntry["placeIds"] as? [String] {
                        totalPlacesCompleted += placeIds.count
                    }
                }
            } else {
                print("無法解析 completedPlace 資料")
            }
            
            // 計算 completedTrip 的總數
            var totalTripsCompleted = 0
            if let completedTrip = data["completedTrip"] as? [String] {
                totalTripsCompleted = completedTrip.count
            } else {
                print("無法解析 completedTrip 資料")
            }
            // 假設第一個 section 是與景點相關的，並且總共有 30 個景點
            let totalTasks = 50
            let section = 0 // 第一個 section
            let row = 0     // 第一個 row
            
            // 使用通用的進度更新函數來更新第一個 cell 的進度條
            self.updateCellProgress(section: 0, row: 0, completedTasks: totalPlacesCompleted, totalTasks: 50)
            self.updateCellProgress(section: 2, row: 0, completedTasks: totalTripsCompleted, totalTasks: 30)
            
            self.categorizePlacesByTag { categorizedPlaces in
                if let tagZeroPlaces = categorizedPlaces[0] {
                    let tagZeroPlacesAmount = tagZeroPlaces.count
                    self.updateCellProgress(section: 1, row: 0, completedTasks: tagZeroPlacesAmount, totalTasks: 30)
                } else if let tagOnePlaces = categorizedPlaces[1] {
                    let tagOnePlacesAmount = tagOnePlaces.count
                    self.updateCellProgress(section: 1, row: 0, completedTasks: tagOnePlacesAmount, totalTasks: 30)
                } else if let tagTwoPlaces = categorizedPlaces[2] {
                    let tagTwoPlacesAmount = tagTwoPlaces.count
                    self.updateCellProgress(section: 1, row: 2, completedTasks: tagTwoPlacesAmount, totalTasks: 30)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    func updateCellProgress(section: Int, row: Int, completedTasks: Int, totalTasks: Int) {
        let progress = Float(completedTasks) / Float(totalTasks)
        
        let indexPath = IndexPath(row: row, section: section)
        if let cell = tableView.cellForRow(at: indexPath) as? AwardTableViewCell {
            cell.milestoneProgressView.progress = progress
        }
    }
    
    func categorizePlacesByTag(completion: @escaping ([Int: [String]]) -> Void) {
        guard let userId = userId else {
            print("無法獲取 userId")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                print("獲取用戶數據時出錯: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, let data = document.data(),
                  let completedPlace = data["completedPlace"] as? [[String: Any]] else {
                print("無法解析 completedPlace 資料")
                return
            }
            
            var categorizedPlaces: [Int: [String]] = [:] // 用來存放不同 tag 對應的 placeId
            
            let dispatchGroup = DispatchGroup() // 用來確保所有 tripId 的查詢完成
            
            for placeEntry in completedPlace {
                if let tripId = placeEntry["tripId"] as? String,
                   let placeIds = placeEntry["placeIds"] as? [String] {
                    
                    dispatchGroup.enter() // 開始一個異步任務
                    
                    // 根據 tripId 去查詢對應的 tag
                    Firestore.firestore().collection("trips").document(tripId).getDocument { (tripSnapshot, error) in
                        if let error = error {
                            print("獲取 trip 資料時出錯: \(error.localizedDescription)")
                            dispatchGroup.leave() // 結束這個異步任務
                            return
                        }
                        
                        guard let tripData = tripSnapshot?.data(),
                              let tag = tripData["tag"] as? Int else {
                            print("無法解析 trip 資料")
                            dispatchGroup.leave() // 結束這個異步任務
                            return
                        }
                        
                        // 將 placeIds 根據 tag 分類
                        if categorizedPlaces[tag] != nil {
                            categorizedPlaces[tag]?.append(contentsOf: placeIds)
                        } else {
                            categorizedPlaces[tag] = placeIds
                        }
                        
                        dispatchGroup.leave() // 當這個 trip 查詢結束時
                    }
                }
            }
            
            // 當所有的查詢都完成時回調
            dispatchGroup.notify(queue: .main) {
                completion(categorizedPlaces) // 回傳分類結果
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return awardSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return awards[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "awardCell", for: indexPath) as? AwardTableViewCell
        
        let taskSet = taskSets[indexPath.section][indexPath.row]
        
        let progress = Float(taskSet.completedTasks) / Float(taskSet.totalTasks)
        
        cell?.awardLabel.text = awards[indexPath.section][indexPath.row]
        cell?.descriptionLabel.text = awardsDescription[indexPath.section][indexPath.row]
        
        cell?.selectionStyle = .none
        cell?.milestoneProgressView.progress = progress
        cell?.milestoneProgressView.milestones = milestones
        
        return cell ?? UITableViewCell()
    }
    
    
    // MARK: - UITableViewDelegate
    
    // 設置每個 section 的行高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180 // 自定義行高度
    }
    
    // 添加 section 的表頭
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .lightGray
        
        let headerLabel = UILabel()
        headerLabel.text = awardSections[section]
        headerLabel.font = UIFont.boldSystemFont(ofSize: 24)
        headerLabel.textColor = .black
        
        headerView.addSubview(headerLabel)
        
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()  // 垂直居中
            make.leading.equalToSuperview().offset(16)  // 與左邊距離 16 點
        }
        
        return headerView
    }
    
    // 設置 section 表頭的高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50 // 自定義表頭高度
    }
    
}
