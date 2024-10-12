//
//  PoemPostViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/9.
//

import Foundation
import UIKit
import SnapKit
import FirebaseFirestore

class PoemPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var bottomSheetManager: BottomSheetManager?
    var allTripIds = [String]()
    var selectedPoem: Poem?
    var filteredPosts = [[String: Any]]()
    var cityGroupedPoems = [String: [[String: Any]]]()
    var tableView: UITableView!
    var emptyStateLabel: UILabel!
    var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundGray
        self.navigationItem.largeTitleDisplayMode = .never
        setupEmptyStateLabel()
        setupScrollView()
        setupTableView()
        self.navigationItem.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.deepBlue
        getCityToTrip()
        
        bottomSheetManager = BottomSheetManager(parentViewController: self, sheetHeight: 200)
        
        bottomSheetManager?.addActionButton(title: "檢舉貼文", textColor: .black) {
            self.presentImpeachAlert()
        }
        bottomSheetManager?.addActionButton(title: "取消", textColor: .red) {
            self.bottomSheetManager?.dismissBottomSheet()
        }
        bottomSheetManager?.setupBottomSheet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        print("ScrollView frame: \(scrollView.frame)")
//        print("ScrollView contentSize: \(scrollView.contentSize)")
//        for subview in scrollView.subviews {
//                if let button = subview as? UIButton {
//                    print("Button Frame: \(button.frame), Title: \(button.titleLabel?.text ?? "")")
//                }
//            }
    }
    
    func setupScrollView() {
            scrollView = UIScrollView()
            scrollView.showsHorizontalScrollIndicator = false
            view.addSubview(scrollView)
            
            scrollView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
                make.leading.trailing.equalTo(view)
                make.height.equalTo(50)
            }
            
            updateScrollViewButtons() // 動態生成按鈕
        }
    
    func updateScrollViewButtons() {
        var buttonX: CGFloat = 10
        let buttonPadding: CGFloat = 10
        let buttonHeight: CGFloat = 40

        // 打印 scrollView 的 frame
        print("------ScrollView frame before adding buttons: \(scrollView.frame)")

        // 创建按钮并添加到 scrollView
        for (index, city) in cityGroupedPoems.keys.enumerated() {
            print("/////", cityGroupedPoems.keys)
            let button = UIButton(type: .system)
            button.setTitle(city, for: .normal)
            button.titleLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 20)
//            button.titleLabel?.textColor = .deepBlue
            button.layer.borderColor = UIColor.deepBlue.cgColor
            button.layer.borderWidth = 1
            button.backgroundColor = .white
            button.setTitleColor(.deepBlue, for: .normal)
            button.layer.cornerRadius = 20
            button.tag = index
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)

            // 设置按钮的宽度
            let buttonWidth = max(80, city.size(withAttributes: [.font: button.titleLabel?.font ?? UIFont.systemFont(ofSize: 17)]).width + 20)
            button.frame = CGRect(x: buttonX, y: 5, width: buttonWidth, height: buttonHeight)
            buttonX += buttonWidth + buttonPadding

            print("Adding button with title: \(city), Frame: \(button.frame)")

            scrollView.addSubview(button)
        }

        // 更新 scrollView 的 contentSize
        scrollView.contentSize = CGSize(width: buttonX, height: buttonHeight)
        print("ScrollView contentSize: \(scrollView.contentSize)")
    }

    @objc func filterButtonTapped(_ sender: UIButton) {
        let section = sender.tag
        let headerRect = tableView.rectForHeader(inSection: section)
        
        // 确保滚动到指定 section 的 header 悬停在 safeArea 的顶部
        let safeAreaTopInset = tableView.safeAreaInsets.top
        let offsetY = max(headerRect.origin.y - safeAreaTopInset, 0)
        
        // 使用 DispatchQueue 确保在布局完成后滚动
        DispatchQueue.main.async {
            self.tableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
        }
    }

    func setupEmptyStateLabel() {
        emptyStateLabel = UILabel()
        emptyStateLabel.text = "現在還沒有這首詩的日記"
        emptyStateLabel.textColor = .lightGray
        emptyStateLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true 
        view.addSubview(emptyStateLabel)
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
    }
    
    func updateEmptyState() {
        print("Filtered Posts Count: \(filteredPosts.count)")
        if filteredPosts.isEmpty {
            print("empty")
            emptyStateLabel.isHidden = false
            tableView.isHidden = true
        } else {
            print("not empty")
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
        }
    }
    // MARK: - TableView 設置
    
    func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserTableViewCell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 240
        tableView.layer.cornerRadius = 20
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
                    make.top.equalTo(scrollView.snp.bottom).offset(10)
                    make.leading.trailing.equalTo(view).inset(16)
                    make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-15)
                }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cityGroupedPoems.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredPosts.count // 返回 filteredPosts 的数量
        //        let city = Array(cityGroupedPoems.keys)[section] // 取得對應的城市
        //                return cityGroupedPoems[city]?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as? UserTableViewCell else {
            return UITableViewCell()
        }
        cell.backgroundColor = .backgroundGray
        cell.selectionStyle = .none
        
        if filteredPosts.isEmpty {
            print("filteredPosts is empty")
        } else {
            let post = filteredPosts[indexPath.row]
//            print("------ ", post)
            cell.configure(with: post)
            
            guard let postOwnerId = post["userId"] as? String else { return UITableViewCell() }
            
            FirebaseManager.shared.fetchUserData(userId: postOwnerId) { result in
                switch result {
                case .success(let data):
                    if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                        
                        DispatchQueue.main.async {
                            cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                        }
                    }
                    
                    cell.userNameLabel.text = data["userName"] as? String
                    
                    FirebaseManager.shared.loadAwardTitle(forUserId: postOwnerId) { (result: Result<(String, Int), Error>) in
                        switch result {
                        case .success(let (awardTitle, item)):
                            let title = awardTitle
                            cell.awardLabelView.updateTitle(awardTitle)
                            DispatchQueue.main.async {
                                AwardStyleManager.updateTitleContainerStyle(
                                    forTitle: awardTitle,
                                    item: item,
                                    titleContainerView: cell.awardLabelView,
                                    titleLabel: cell.awardLabelView.titleLabel,
                                    dropdownButton: nil
                                )
                            }
                            
                        case .failure(let error):
                            print("獲取稱號失敗: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    print("加載用戶大頭貼失敗: \(error.localizedDescription)")
                }
            }
        }
        
        cell.configureMoreButton {
            self.bottomSheetManager?.showBottomSheet()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = filteredPosts[indexPath.row]
        
        let articleVC = ArticleViewController()
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
                articleVC.tripId = post["tripId"] as? String ?? ""
                articleVC.photoUrls = post["photoUrls"] as? [String] ?? []
                if let createdAtTimestamp = post["createdAt"] as? Timestamp {
                    let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
                    articleVC.articleDate = createdAtString
                }
                
                articleVC.authorId = post["userId"] as? String ?? ""
                articleVC.postId = post["id"] as? String ?? ""
                articleVC.bookmarkAccounts = post["bookmarkAccount"] as? [String] ?? []
                
                self.navigationController?.pushViewController(articleVC, animated: true)
            } else {
                print("未找到對應的 userName")
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 创建一个 UIView 作为 section 的 header
        let headerView = UIView()
        headerView.backgroundColor = .backgroundGray // 设置背景色
        
        // 创建 UILabel 来显示标题
        let titleLabel = UILabel()
        titleLabel.text = Array(cityGroupedPoems.keys)[section] // 设置文本为城市名
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        titleLabel.textColor = .deepBlue // 自定义文字颜色
        
        headerView.addSubview(titleLabel)
        
        // 使用 Auto Layout 进行布局
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16), // 左边有间距
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor) // 垂直居中
        ])
        
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60 // 自定义的 header 高度
    }
    
    // MARK: - 加載數據
    
    func loadFilteredPosts(allTripIds: [String], completion: @escaping ([[String: Any]]) -> Void) {
        // 检查是否有 TripId
        guard !allTripIds.isEmpty else {
            completion([])
            return
        }
        
        FirebaseManager.shared.loadPosts { [weak self] postsArray in
            guard let self = self else { return }
            
            // 过滤出与给定 tripId 匹配的帖子
            let filteredPosts = postsArray.filter { postData in
                guard let tripId = postData["tripId"] as? String else { return false }
                return allTripIds.contains(tripId)
            }
            
            // 将过滤后的帖子返回
            completion(filteredPosts)
        }
    }
    
    func presentImpeachAlert() {
            let alertController = UIAlertController(title: "檢舉貼文", message: "你確定要檢舉這篇貼文嗎？", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "確定", style: .destructive) { _ in
                self.bottomSheetManager?.dismissBottomSheet()
            }
            alertController.addAction(confirmAction)
            
            present(alertController, animated: true, completion: nil)
        }
    
    func getCityToTrip() {
        if let selectedPoem = selectedPoem {
            FirebaseManager.shared.getCityToTrip(poemId: selectedPoem.id) { poemsArray, error in
                if let error = error {
                    print("Error retrieving data: \(error.localizedDescription)")
                    return
                } else if let poemsArray = poemsArray {
                    print("++++++    ", poemsArray)
                    for poem in poemsArray {
                        if let city = poem["city"] as? String {
                            print("city isn't empty")
                            if var existingPoems = self.cityGroupedPoems[city] {
                                existingPoems.append(poem)
                                self.cityGroupedPoems[city] = existingPoems
                            } else {
                                self.cityGroupedPoems[city] = [poem]
                            }
                        }
                        
                        if let tripId = poem["tripId"] as? String {
                            print("tripId: \(tripId)")
                            self.allTripIds.append(tripId)
                        }
                    }
                    print("All Trip Ids: \(self.allTripIds)")
                    
                    // Load filtered posts and update table view
                    self.loadFilteredPosts(allTripIds: self.allTripIds) { filteredPosts in
                        self.filteredPosts = filteredPosts
                        
                        print("Filtered Posts: \(self.filteredPosts)")
                        self.updateEmptyState()
//                        self.setupScrollView()
                        self.updateScrollViewButtons()
                        self.tableView.reloadData() 
                    }
                } else {
                    self.updateEmptyState()
                }
            }
        }
    }
}
