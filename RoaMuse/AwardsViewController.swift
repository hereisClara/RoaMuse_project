import UIKit
import SnapKit
import FirebaseFirestore

class AwardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    let awards = [
        ["踩點之路"], // 第 1 個 section
        ["浪漫大師", "奇險大師", "田園大師"],    // 第 2 個 section
        ["走到終點"]                   // 第 3 個 section
    ]
    
    let awardSections = ["踩點總集", "風格master", "有始有終"]
    
    // 模擬的進度數據
    let progressValues: [[Float]] = [
        [0.8],   // 第 1 個 section
        [0.7, 0.6, 0.3],        // 第 2 個 section
        [0.9]              // 第 3 個 section
    ]
    
    var taskSets: [[TaskSet]] = [
        [TaskSet(totalTasks: 30, completedTasks: 15)],  // 第 1 个任务集合（cell）
        [TaskSet(totalTasks: 50, completedTasks: 25),
         TaskSet(totalTasks: 40, completedTasks: 15),
         TaskSet(totalTasks: 30, completedTasks: 15)],  // 第 2 个任务集合（cell）
        [TaskSet(totalTasks: 20, completedTasks: 10),
         TaskSet(totalTasks: 50, completedTasks: 15)]   // 第 3 个任务集合（cell）
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
            
            guard let document = documentSnapshot, let data = document.data(),
                  let completedPlace = data["completedPlace"] as? [[String: Any]] else {
                print("無法解析 completedPlace 資料")
                return
            }
            
            // 計算 completedPlace 中 placeIds 的總數
            var totalPlacesCompleted = 0
            for placeEntry in completedPlace {
                if let placeIds = placeEntry["placeIds"] as? [String] {
                    totalPlacesCompleted += placeIds.count
                }
            }
            // 假設第一個 section 是與景點相關的，並且總共有 30 個景點
            let totalTasks = 50
            let section = 0 // 第一個 section
            let row = 0     // 第一個 row
            
            // 使用通用的進度更新函數來更新第一個 cell 的進度條
            self.updateCellProgress(section: section, row: row, completedPlaces: totalPlacesCompleted, totalTasks: totalTasks)
        }
    }
    
    func updateCellProgress(section: Int, row: Int, completedPlaces: Int, totalTasks: Int) {
        // 計算進度
        let progress = Float(completedPlaces) / Float(totalTasks)
        
        // 根據 section 和 row 找到對應的 cell
        let indexPath = IndexPath(row: row, section: section)
        if let cell = tableView.cellForRow(at: indexPath) as? AwardTableViewCell {
            cell.milestoneProgressView.progress = progress
        }
    }
    // MARK: - UITableViewDataSource
    
    // 返回 section 的數量
    func numberOfSections(in tableView: UITableView) -> Int {
        return awardSections.count
    }
    
    // 每個 section 的行數
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return awards[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "awardCell", for: indexPath) as? AwardTableViewCell
        
        let taskSet = taskSets[indexPath.section][indexPath.row]
        
        let progress = Float(taskSet.completedTasks) / Float(taskSet.totalTasks)
        
        cell?.awardLabel.text = awards[indexPath.section][indexPath.row]
        
        cell?.milestoneProgressView.progress = progress
        
        cell?.milestoneProgressView.milestones = milestones
        
        return cell ?? UITableViewCell()
    }


    // MARK: - UITableViewDelegate

    // 設置每個 section 的行高度
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160 // 自定義行高度
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
        
        // 使用 SnapKit 設置 headerLabel 的 Auto Layout
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
