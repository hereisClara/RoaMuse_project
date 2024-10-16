import UIKit
import SnapKit
import FirebaseFirestore

class AwardsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let dropdownMenu = DropdownMenu(items: ["探索者", "街頭土行孫", "現世行腳仙", "浪漫1", "奇險1", "田園1"])
    var titlesWithIndexes: [(title: String, section: Int, row: Int)] = []
    let dropdownButton = UIButton(type: .system)
    var dynamicTaskSets: [[TaskSet]] = []
    let tableView = UITableView()
    let headerLabel = UILabel()
    let titleContainerView = UIView()
    var currentTitles: [String] = []
    var userName = String()
    var avatarImageUrl = String()
    var selectedTitle = String()
    var titleLabel = UILabel()
    let circularProgressBar = CircularProgressBar(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
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
    
    let awardTitles = [
        [["復得返自然", "人生如逆旅", "無事小神仙"]],
        [["世間行樂亦如此", "落花踏盡游何處", "含光混世貴無名"], ["若個書生萬戶侯", "月寒日暖煎人壽", "走月逆行雲"], ["獨出前門望野田", "夕露沾我衣", "惟有幽人自來去"]],
        [["且放白鹿青崖間", "大地有緣能自遇", "得似浮雲也自由"]]
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
        view.backgroundColor = .backgroundGray
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.barTintColor = UIColor.deepBlue
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "NotoSerifHK-Black", size: 18)
        ]
        self.title = "成就"
        
        setupTableView()
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserData()
        tabBarController?.tabBar.isHidden = true
        navigationController?.navigationBar.isTranslucent = true
        
        dropdownMenu.onItemSelected = { [weak self] selectedItem in
            guard let self = self else { return }
            self.titleLabel.text = selectedItem
            if let (section, row, item) = self.findIndexesForTitle(selectedItem) {
                self.updateTitleContainerStyle(forProgressAt: section, row: row, item: item)
                self.saveSelectedIndexesToFirebase(section: section, row: row, item: item)
//                print("已保存的索引: section = \(section), row = \(row), item = \(item)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.barTintColor = UIColor.backgroundGray
        navigationController?.navigationBar.tintColor = UIColor.deepBlue
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "NotoSerifHK-Black", size: 18)
        ]
        tabBarController?.tabBar.isHidden = false
    }
    
    func findIndexesForTitle(_ title: String) -> (Int, Int, Int)? {
        for section in 0..<awardTitles.count {
            for row in 0..<awardTitles[section].count {
                if let itemIndex = awardTitles[section][row].firstIndex(of: title) {
                    return (section, row, itemIndex)  // 返回 section, row 和 item 索引
                }
            }
        }
        return nil
    }
    
    func saveSelectedIndexesToFirebase(section: Int, row: Int, item: Int) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        let indexArray = [section, row, item]
        
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
        switch item {
        case 0:
            // 進度點 1
            titleContainerView.backgroundColor = UIColor.forBronze
            titleLabel.textColor = .white
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
            dropdownButton.tintColor = .white
            
        case 1:
            // 進度點 2
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderColor = UIColor.deepBlue.cgColor // 編框 .deepBlue
            titleContainerView.layer.borderWidth = 2.0 // 設置邊框寬度
            titleLabel.textColor = .deepBlue
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
            dropdownButton.tintColor = .deepBlue
            
        case 2:
            // 進度點 3
            titleContainerView.backgroundColor = UIColor.accent // 底色為 .accent
            titleContainerView.layer.borderWidth = 0.0 // 沒有邊框
            titleLabel.textColor = .white
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
            dropdownButton.tintColor = .white
            
        default:
            // 預設情況，無邊框及默認顏色
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderWidth = 0.0
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        }
    }

    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.register(AwardTableViewCell.self, forCellReuseIdentifier: "awardCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setupTableViewHeader() {
        let headerView = UIView()
        headerView.backgroundColor = .deepBlue

        headerView.layer.cornerRadius = 30
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.layer.masksToBounds = true

        let completedTasks = currentTitles.count
        let totalTasks = 15
        circularProgressBar.progress = Float(completedTasks) / Float(totalTasks) // 設置進度
        headerView.addSubview(circularProgressBar)

        headerLabel.text = userName
        headerLabel.font = UIFont(name: "NotoSerifHK-Black", size: 26)
        headerLabel.textColor = .white

        titleLabel.text = selectedTitle
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        
        dropdownButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        dropdownButton.addTarget(self, action: #selector(showDropdownMenu), for: .touchUpInside)

        titleContainerView.addSubview(titleLabel)
        titleContainerView.addSubview(dropdownButton)
        headerView.addSubview(headerLabel)
        headerView.addSubview(titleContainerView)

        headerLabel.snp.makeConstraints { make in
            make.leading.equalTo(circularProgressBar.snp.trailing).offset(16)
            make.top.equalTo(circularProgressBar).offset(20)
        }

        titleContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.equalTo(headerLabel)
            make.width.equalTo(174)
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
            make.leading.equalToSuperview().offset(20)
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
        self.view.layoutIfNeeded()
        if dropdownMenu.superview == nil {
            dropdownMenu.show(in: self.view, anchorView: titleContainerView)
        } else {
            tableView.reloadData()
            dropdownMenu.hide()
        }
    }
    
    func fetchUserData() {
        guard let userId = userId else {
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.addSnapshotListener { (documentSnapshot, error) in
            if let error = error {
                print("獲取用戶數據時出錯: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, let data = document.data() else {
                print("無法解析用戶數據")
                return
            }
            
            self.userName = data["userName"] as? String ?? "使用者"
            let avatarImageUrl = data["photo"] as? String ?? ""
            
            if avatarImageUrl != self.avatarImageUrl {
                        self.avatarImageUrl = avatarImageUrl
                        if let url = URL(string: avatarImageUrl) {
                            self.circularProgressBar.setAvatarImage(from: url)
                        }
                    }
            
            // 加載用戶的當前選擇的 title
            FirebaseManager.shared.loadAwardTitle(forUserId: userId) { result in
                switch result {
                case .success(let awardTitle):
                    DispatchQueue.main.async {
                        self.selectedTitle = awardTitle.0
                        self.titleLabel.text = self.selectedTitle
                        self.titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
                        
                        if let (section, row, item) = self.findIndexesForTitle(awardTitle.0) {
                            self.updateTitleContainerStyle(forProgressAt: section, row: row, item: item)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.selectedTitle = "初心者"
                        self.titleLabel.textColor = .white
                        self.titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
                        self.titleLabel.text = self.selectedTitle
                        self.dropdownButton.tintColor = .white
                        self.titleContainerView.backgroundColor = .lightGray
                    }
                }
            }
            
            // 如果没有 completedPlace 数据，进度为 0
            let totalPlacesCompleted = (data["completedPlace"] as? [[String: Any]])?.reduce(0) { acc, placeEntry in
                acc + ((placeEntry["placeIds"] as? [String])?.count ?? 0)
            } ?? 0
            
            // 如果没有 completedTrip 数据，进度为 0
            let totalTripsCompleted = (data["completedTrip"] as? [String])?.count ?? 0
            
            // 初始化动态的任务集合
            self.dynamicTaskSets = [
                [TaskSet(totalTasks: 20, completedTasks: totalPlacesCompleted)],
                [TaskSet(totalTasks: 10, completedTasks: 0),
                 TaskSet(totalTasks: 10, completedTasks: 0),
                 TaskSet(totalTasks: 10, completedTasks: 0)],
                [TaskSet(totalTasks: 6, completedTasks: totalTripsCompleted)]
            ]
            
            // 分类地点并更新进度
            self.categorizePlacesByTag { categorizedPlaces in
                let tagZeroPlacesAmount = categorizedPlaces[0]?.count ?? 0
                self.dynamicTaskSets[1][0] = TaskSet(totalTasks: 10, completedTasks: tagZeroPlacesAmount)
                
                let tagOnePlacesAmount = categorizedPlaces[1]?.count ?? 0
                self.dynamicTaskSets[1][1] = TaskSet(totalTasks: 10, completedTasks: tagOnePlacesAmount)
                
                let tagTwoPlacesAmount = categorizedPlaces[2]?.count ?? 0
                self.dynamicTaskSets[1][2] = TaskSet(totalTasks: 10, completedTasks: tagTwoPlacesAmount)
                
                // 计算所有称号的进度，并直接更新下拉菜单
                self.calculateTitlesAndUpdateDropDown()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
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
        
        dropdownMenu.items = currentTitles
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180 // 自定義行高度
    }
    
    // 添加 section 的表頭
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        let headerLabel = UILabel()
        headerLabel.text = awardSections[section]
        headerLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        headerLabel.textColor = .deepBlue
        
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
    
    func calculateTitlesAndUpdateDropDown() {
        titlesWithIndexes.removeAll()  // 清空舊資料，避免重複
        
        for section in 0..<self.dynamicTaskSets.count {
            for row in 0..<self.dynamicTaskSets[section].count {
                let taskSet = self.dynamicTaskSets[section][row]
                let progress = Float(taskSet.completedTasks) / Float(taskSet.totalTasks)
                
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
                        currentTitles.append(title)  // 保留舊的 currentTitles
                    }
                    titlesWithIndexes.append((title: title, section: section, row: row))
                }
            }
        }
        dropdownMenu.titlesWithIndexes = titlesWithIndexes
        dropdownMenu.items = currentTitles
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
                completion([:])
                return
            }
            
            guard let document = documentSnapshot, let data = document.data(),
                  let completedPlace = data["completedPlace"] as? [[String: Any]] else {
                print("無法解析 completedPlace 資料")
                completion([:])
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
