import UIKit
import SnapKit
import FirebaseFirestore

class AwardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let dropdownMenu = DropdownMenu(items: ["探索者", "街頭土行孫", "現世行腳仙", "浪漫1", "奇險1", "田園1"])
    let dropdownButton = UIButton(type: .system)
    var dynamicTaskSets: [[TaskSet]] = []
    let tableView = UITableView()
    var currentTitles: [String] = []
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    let awards = [
        ["踩點之路"], // 第 1 個 section
        ["浪漫大師", "奇險大師", "田園大師"],    // 第 2 個 section
        ["走到終點"]                   // 第 3 個 section
    ]
    
    let awardsDescription: [[String]] = [
        ["一路走來，你已經走過了這麼多地方⋯⋯"],
        ["在成為浪漫大師的路上", "在成為冒險者的路上", "在走向鄉野的路上"],
        ["有始有終，行萬卷書與你一起走過⋯⋯"]
    ]
    
    let awardTitles: [[[String]]] = [
        [["探索者", "街頭土行孫", "現世行腳仙"]],  // 第 1 個 row 的稱號
        
        [["浪漫1", "浪漫2", "浪漫3"],   // 第 2 個 row 的稱號
        ["奇險1", "奇險2", "奇險3"],
         ["田園1","田園2", "田園3"]],// 第 3 個 row 的稱號
        
        [["終點1", "終點2", "終點3"]]
    ]

    let awardSections = ["踩點總集", "風格master", "有始有終"]
    
    let milestones: [Float] = [0.3, 0.6, 1.0]
    
        var taskSets: [[TaskSet]] = [
            [TaskSet(totalTasks: 30, completedTasks: 30)],  // 第 1 个任务集合（cell）
            [TaskSet(totalTasks: 50, completedTasks: 50),
             TaskSet(totalTasks: 40, completedTasks: 40),
             TaskSet(totalTasks: 30, completedTasks: 30)],  // 第 2 个任务集合（cell）
            [TaskSet(totalTasks: 20, completedTasks: 20),
             TaskSet(totalTasks: 50, completedTasks: 50)]   // 第 3 个任务集合（cell）
        ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        fetchUserData()
        setupTableView()
        setupTableViewHeader()
        self.navigationItem.largeTitleDisplayMode = .never
        dropdownMenu.onItemSelected = { [weak self] selectedItem in
            guard let self = self else { return }
            
            if let (section, row, item) = self.findIndexesForTitle(selectedItem) {
                self.saveSelectedIndexesToFirebase(section: section, row: row, item: item)
                print("已保存的索引: section = \(section), row = \(row), item = \(item)")
            }
        }
    }
    
    func findIndexesForTitle(_ title: String) -> (Int, Int, Int)? {
        for section in 0..<awardTitles.count {
            for row in 0..<awardTitles[section].count {
                if let itemIndex = awardTitles[section][row].firstIndex(of: title) {
                    return (section, row, itemIndex)  // 返回 section, row 和 item 索引
                }
            }
        }
        return nil  // 如果找不到则返回 nil
    }
    
    func saveSelectedIndexesToFirebase(section: Int, row: Int, item: Int) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        let indexArray = [section, row, item]
        
        // 儲存資料到 Firebase
        userRef.setData(["selectedTitleIndex": indexArray], merge: true) { error in
            if let error = error {
                print("保存到 Firebase 時出錯: \(error.localizedDescription)")
            } else {
                print("成功保存到 Firebase: \(indexArray)")
                let selectedTitle = self.awardTitles[section][row][item]
                NotificationCenter.default.post(name: NSNotification.Name("awardUpdated"), object: nil, userInfo: ["title": selectedTitle])
            }
        }
    }

    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.register(AwardTableViewCell.self, forCellReuseIdentifier: "awardCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        dropdownButton.setTitle("查看稱號", for: .normal)
        dropdownButton.addTarget(self, action: #selector(showDropdownMenu), for: .touchUpInside)
        
        tableHeaderView.addSubview(dropdownButton)
        dropdownButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        
        tableHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100)
        tableView.tableHeaderView = tableHeaderView
    }
    
    @objc func showDropdownMenu() {
        if dropdownMenu.superview == nil {  // 如果還未顯示
            dropdownMenu.show(in: self.view, anchorView: dropdownButton)
        } else {
            dropdownMenu.hide()
        }
    }
    
    func fetchUserData() {
        guard let userId = userId else {
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
            
            var totalTripsCompleted = 0
            if let completedTrip = data["completedTrip"] as? [String] {
                totalTripsCompleted = completedTrip.count
            } else {
                print("無法解析 completedTrip 資料")
            }
            
            // 更新動態的任務集合
            self.dynamicTaskSets = [
                [TaskSet(totalTasks: 20, completedTasks: totalPlacesCompleted)],
                [],
                [TaskSet(totalTasks: 6, completedTasks: totalTripsCompleted)]
            ]
            
            self.categorizePlacesByTag { categorizedPlaces in
                let tagZeroPlacesAmount = categorizedPlaces[0]?.count ?? 0
                self.dynamicTaskSets[1].append(TaskSet(totalTasks: 10, completedTasks: tagZeroPlacesAmount))
                
                let tagOnePlacesAmount = categorizedPlaces[1]?.count ?? 0
                self.dynamicTaskSets[1].append(TaskSet(totalTasks: 10, completedTasks: tagOnePlacesAmount))
                
                let tagTwoPlacesAmount = categorizedPlaces[2]?.count ?? 0
                self.dynamicTaskSets[1].append(TaskSet(totalTasks: 10, completedTasks: tagTwoPlacesAmount))
                
                // 計算所有稱號的進度，並直接更新 dropDown
                self.calculateTitlesAndUpdateDropDown()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()  // 確保所有 `cell` 被重新加載
                }
            }
        }
    }

    // 新增方法，根據數據計算稱號並更新 dropDown
    func calculateTitlesAndUpdateDropDown() {
        for section in 0..<self.dynamicTaskSets.count {
            for row in 0..<self.dynamicTaskSets[section].count {
                let taskSet = self.dynamicTaskSets[section][row]
                let progress = Float(taskSet.completedTasks) / Float(taskSet.totalTasks)
                
                // 計算稱號
                let titlesForRow = awardTitles[section][row]
                var obtainedTitles: [String] = []
                
                if isProgressEqualOrGreater(progress, than: 1.0) {
                    obtainedTitles = titlesForRow
                } else if isProgressEqualOrGreater(progress, than: 0.6) {
                    obtainedTitles = Array(titlesForRow[0...1])
                } else if isProgressEqualOrGreater(progress, than: 0.3) {
                    obtainedTitles = [titlesForRow[0]]
                }
                
                // 將獲得的稱號加入 dropDown
                for title in obtainedTitles {
                    if !currentTitles.contains(title) {
                        currentTitles.append(title)
                    }
                }
            }
        }
        
        // 更新下拉選單
        dropdownMenu.items = currentTitles
        print("更新後的稱號: \(currentTitles)")
    }
    
    // 保留現有的 isProgressEqualOrGreater 方法
    func isProgressEqualOrGreater(_ progress: Float, than value: Float) -> Bool {
        let epsilon: Float = 0.0001
        return progress > value - epsilon
    }

    // 保留 categorizePlacesByTag 的邏輯
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
            
            var categorizedPlaces: [Int: [String]] = [:]
            
            let dispatchGroup = DispatchGroup()
            
            for placeEntry in completedPlace {
                if let tripId = placeEntry["tripId"] as? String,
                   let placeIds = placeEntry["placeIds"] as? [String] {
                    
                    dispatchGroup.enter()
                    
                    Firestore.firestore().collection("trips").document(tripId).getDocument { (tripSnapshot, error) in
                        if let error = error {
                            print("獲取 trip 資料時出錯: \(error.localizedDescription)")
                            dispatchGroup.leave()
                            return
                        }
                        
                        guard let tripData = tripSnapshot?.data(),
                              let tag = tripData["tag"] as? Int else {
                            print("無法解析 trip 資料")
                            dispatchGroup.leave()
                            return
                        }
                        
                        if categorizedPlaces[tag] != nil {
                            categorizedPlaces[tag]?.append(contentsOf: placeIds)
                        } else {
                            categorizedPlaces[tag] = placeIds
                        }
                        
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(categorizedPlaces)
            }
        }
    }

    // 保留 tableView 的數據源和委託方法
    func numberOfSections(in tableView: UITableView) -> Int {
        return dynamicTaskSets.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dynamicTaskSets[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "awardCell", for: indexPath) as? AwardTableViewCell else {
            return UITableViewCell()
        }

        let awardTitle = awards[indexPath.section][indexPath.row]
        let awardDesc = awardsDescription[indexPath.section][indexPath.row]

        cell.awardLabel.text = awardTitle
        cell.descriptionLabel.text = awardDesc
        cell.selectionStyle = .none
        cell.milestoneProgressView.milestones = milestones

        // 確保 progress 是根據資料正確設置的
        if indexPath.section < dynamicTaskSets.count && indexPath.row < dynamicTaskSets[indexPath.section].count {
            let taskSet = self.dynamicTaskSets[indexPath.section][indexPath.row]
            let progress = Float(taskSet.completedTasks) / Float(taskSet.totalTasks)

            // 更新進度條
            cell.milestoneProgressView.progress = progress
            updateAwardTitles(section: indexPath.section, row: indexPath.row, progress: progress)
        } else {
            // 當無數據時，將進度設置為 0
            cell.milestoneProgressView.progress = 0.0
        }

        return cell
    }
    
    func updateAwardTitles(section: Int, row: Int, progress: Float) {
        let titlesForRow = awardTitles[section][row]
        var obtainedTitles: [String] = []
        
        if isProgressEqualOrGreater(progress, than: 1.0) {
            obtainedTitles = titlesForRow
        } else if isProgressEqualOrGreater(progress, than: 0.6) {
            obtainedTitles = Array(titlesForRow[0...1])
        } else if isProgressEqualOrGreater(progress, than: 0.3) {
            obtainedTitles = [titlesForRow[0]]
        }
        
        for title in obtainedTitles {
            if !currentTitles.contains(title) {
                currentTitles.append(title)
            }
        }
        
        // 更新下拉選單
        dropdownMenu.items = currentTitles
    }
    
    // MARK: - UITableViewDelegate
    
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
