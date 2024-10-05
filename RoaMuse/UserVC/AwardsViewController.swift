import UIKit
import SnapKit
import FirebaseFirestore

class AwardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let dropdownMenu = DropdownMenu(items: ["探索者", "街頭土行孫", "現世行腳仙", "浪漫1", "奇險1", "田園1"])
    let dropdownButton = UIButton(type: .system)
    var dynamicTaskSets: [[TaskSet]] = []
    let tableView = UITableView()
    let titleContainerView = UIView()
    var currentTitles: [String] = []
    var userName = String()
    var avatarImageUrl = String()
    var selectedTitle = String()
    var titleLabel = UILabel()
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
//        fetchUserData()
        self.title = "成就"
        
        setupTableView()
//        setupTableViewHeader()
        self.navigationItem.largeTitleDisplayMode = .never
        dropdownMenu.onItemSelected = { [weak self] selectedItem in
            guard let self = self else { return }
            self.titleLabel.text = selectedItem
            if let (section, row, item) = self.findIndexesForTitle(selectedItem) {
                self.updateTitleContainerStyle(forProgressAt: section, row: row, item: item)
                self.saveSelectedIndexesToFirebase(section: section, row: row, item: item)
                print("已保存的索引: section = \(section), row = \(row), item = \(item)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserData()
//        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = UIColor.deepBlue
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
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
    
    func updateTitleContainerStyle(forProgressAt section: Int, row: Int, item: Int) {
        // 根據 section, row 或 item 來決定進度點
        // 假設 item 0 表示進度點1, item 1 表示進度點2, item 2 表示進度點3
        switch item {
        case 0:
            // 進度點 1
            titleContainerView.backgroundColor = UIColor.brown // 深棕色
            titleContainerView.layer.borderColor = UIColor.lightGray.cgColor // 編框淺灰色
            titleContainerView.layer.borderWidth = 2.0 // 設置邊框寬度
            titleLabel.textColor = .white
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            dropdownButton.tintColor = .white
            
        case 1:
            // 進度點 2
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderColor = UIColor.deepBlue.cgColor // 編框 .deepBlue
            titleContainerView.layer.borderWidth = 2.0 // 設置邊框寬度
            titleLabel.textColor = .deepBlue
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            dropdownButton.tintColor = .deepBlue
            
        case 2:
            // 進度點 3
            titleContainerView.backgroundColor = UIColor.accent // 底色為 .accent
            titleContainerView.layer.borderWidth = 0.0 // 沒有邊框
            titleLabel.textColor = .white
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            dropdownButton.tintColor = .white
            
        default:
            // 預設情況，無邊框及默認顏色
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderWidth = 0.0
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
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
        // 創建一個包含進度條的Header View
        let headerView = UIView()
        headerView.backgroundColor = .deepBlue

        // 設置圓角，只對下方兩個角進行圓角處理
        headerView.layer.cornerRadius = 30
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.layer.masksToBounds = true

        // 設置圓形進度條
        let circularProgressBar = CircularProgressBar(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        if let url = URL(string: avatarImageUrl) {
            circularProgressBar.setAvatarImage(from: url)
        }
        let completedTasks = currentTitles.count
        let totalTasks = 15
        circularProgressBar.progress = Float(completedTasks) / Float(totalTasks) // 設置進度
        headerView.addSubview(circularProgressBar)

        // 添加標題
        let headerLabel = UILabel()
        headerLabel.text = userName
        headerLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 32)
        headerLabel.textColor = .white

        titleLabel.text = selectedTitle

        dropdownButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        dropdownButton.addTarget(self, action: #selector(showDropdownMenu), for: .touchUpInside)

        // 將 titleLabel 和 dropdownButton 添加到 titleContainerView 中
        titleContainerView.addSubview(titleLabel)
        titleContainerView.addSubview(dropdownButton)

        // 添加 headerLabel 和 titleContainerView 到 headerView
        headerView.addSubview(headerLabel)
        headerView.addSubview(titleContainerView)

        // 使用 SnapKit 進行佈局
        headerLabel.snp.makeConstraints { make in
            make.leading.equalTo(circularProgressBar.snp.trailing).offset(20)
            make.top.equalTo(circularProgressBar).offset(20)
        }

        // titleContainerView 的佈局，寬 100，高 60
        titleContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.equalTo(headerLabel)
            make.width.equalTo(150)
            make.height.equalTo(45)
        }
        
        titleContainerView.layer.cornerRadius = 15

        // titleLabel 的佈局
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        // dropdownButton 的佈局，緊靠 titleLabel 並且距離右邊有 -12 的偏移
        dropdownButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        // circularProgressBar 的佈局
        circularProgressBar.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(30)
            make.width.height.equalTo(160)
            make.leading.equalToSuperview().offset(30)
        }

        // 設置背景延伸到 NavigationBar 區域
        let extendedHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
        extendedHeaderView.backgroundColor = UIColor.clear
        extendedHeaderView.addSubview(headerView)

        headerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
            make.top.equalToSuperview().offset(-100)
        }

        tableView.tableHeaderView = extendedHeaderView
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
            
            self.userName = data["userName"] as? String ?? "使用者"
            self.avatarImageUrl = data["photo"] as? String ?? ""
            
            // 加載用戶的當前選擇的 title
            FirebaseManager.shared.loadAwardTitle(forUserId: userId) { result in
                switch result {
                case .success(let awardTitle):
                    DispatchQueue.main.async {
                        self.selectedTitle = awardTitle
                        self.titleLabel.text = self.selectedTitle
                        
                        // 查找選擇的 title 對應的索引，並更新樣式
                        if let (section, row, item) = self.findIndexesForTitle(awardTitle) {
                            self.updateTitleContainerStyle(forProgressAt: section, row: row, item: item)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.selectedTitle = "初心者"
                        self.titleLabel.text = self.selectedTitle
                    }
                }
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
                    self.tableView.reloadData()
    //                    self.setupTableView()
                    self.setupTableViewHeader()
                }
            }
        }
    }

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

extension AwardsViewController {
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

}
