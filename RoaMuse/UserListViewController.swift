//
//  UserListViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import FirebaseFirestore
import UIKit
import SnapKit

class UserListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    var followersData: [[String: Any]] = []
    var followingData: [[String: Any]] = []
    var followers: [String] = []
    var following: [String] = []
    var userId: String?
    var isShowingFollowers: Bool = true
    let followersButton = UIButton() // 左邊的粉絲按鈕
    let followingButton = UIButton() // 右邊的關注按鈕
    let underlineView = UIView() // 底部黑色線條
    let scrollView = UIScrollView() // 用來左右滑動
    let followersTableView = UITableView() // 顯示粉絲列表
    let followingTableView = UITableView() // 顯示關注者列表
    let followersPlaceholderLabel = UILabel()
    let followingPlaceholderLabel = UILabel()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationItem.largeTitleDisplayMode = .never
        setupButtons()
        setupUnderlineView()
        setupScrollView()
        setupTableViews()
        setupPlaceholders()
        
        if isShowingFollowers {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            updateUnderlinePosition(button: followersButton)
        } else {
            scrollView.setContentOffset(CGPoint(x: view.frame.width, y: 0), animated: false)
            updateUnderlinePosition(button: followingButton)
        }
        loadUserList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func setupButtons() {
        followersButton.setTitle("Followers", for: .normal)
        followersButton.setTitleColor(.black, for: .selected)
        followersButton.setTitleColor(.gray, for: .normal)
        followersButton.isSelected = true
        followersButton.addTarget(self, action: #selector(followersButtonTapped), for: .touchUpInside)
        
        followingButton.setTitle("Following", for: .normal)
        followingButton.setTitleColor(.black, for: .selected)
        followingButton.setTitleColor(.gray, for: .normal)
        followingButton.addTarget(self, action: #selector(followingButtonTapped), for: .touchUpInside)
        
        let buttonStackView = UIStackView(arrangedSubviews: [followersButton, followingButton])
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        view.addSubview(buttonStackView)
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(50)
        }
    }
    
    func setupUnderlineView() {
        underlineView.backgroundColor = .black
        view.addSubview(underlineView)
        
        underlineView.snp.makeConstraints { make in
            make.top.equalTo(followersButton.snp.bottom)
            make.leading.equalTo(followersButton)
            make.width.equalTo(followersButton)
            make.height.equalTo(3)
        }
    }
    
    func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(underlineView.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.contentSize = CGSize(width: view.frame.width * 2, height: scrollView.frame.height)
    }
    
    // 設置兩個 TableViews
    func setupTableViews() {
        followersTableView.delegate = self
        followersTableView.dataSource = self
        followersTableView.register(FollowerFollowingTableViewCell.self, forCellReuseIdentifier: "followerCell")
        scrollView.addSubview(followersTableView)
        
        followersTableView.snp.makeConstraints { make in
            make.leading.equalTo(scrollView.snp.leading)
            make.top.equalTo(scrollView.snp.top)
            make.width.equalTo(view.frame.width)
            make.height.equalTo(scrollView.snp.height)
        }
        
        followingTableView.delegate = self
        followingTableView.dataSource = self
        followingTableView.register(FollowerFollowingTableViewCell.self, forCellReuseIdentifier: "followingCell")
        scrollView.addSubview(followingTableView)
        
        followingTableView.snp.makeConstraints { make in
            make.leading.equalTo(followersTableView.snp.trailing)
            make.top.equalTo(scrollView.snp.top)
            make.width.equalTo(view.frame.width)
            make.height.equalTo(scrollView.snp.height)
        }
    }
//    MARK: placeholder
    func setupPlaceholders() {
        // 粉絲 Placeholder
        followersPlaceholderLabel.text = "還沒有粉絲"
        followersPlaceholderLabel.textAlignment = .center
        followersPlaceholderLabel.textColor = .gray
        followersPlaceholderLabel.font = UIFont.systemFont(ofSize: 18)
        followersPlaceholderLabel.isHidden = true
        followersTableView.superview?.addSubview(followersPlaceholderLabel) // 加到 TableView 的父視圖上

        // 關注者 Placeholder
        followingPlaceholderLabel.text = "還沒有追蹤者"
        followingPlaceholderLabel.textAlignment = .center
        followingPlaceholderLabel.textColor = .gray
        followingPlaceholderLabel.font = UIFont.systemFont(ofSize: 18)
        followingPlaceholderLabel.isHidden = true
        followingTableView.superview?.addSubview(followingPlaceholderLabel) // 加到 TableView 的父視圖上

        // 設定 Placeholder 的約束，使其蓋在 TableView 上
        followersPlaceholderLabel.snp.makeConstraints { make in
            make.edges.equalTo(followersTableView) // 完全覆蓋在 TableView 上
        }

        followingPlaceholderLabel.snp.makeConstraints { make in
            make.edges.equalTo(followingTableView) // 完全覆蓋在 TableView 上
        }
    }

    // MARK: - Button actions
    @objc func followersButtonTapped() {
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        updateUnderlinePosition(button: followersButton)
        loadUserList()
    }
    
    @objc func followingButtonTapped() {
        scrollView.setContentOffset(CGPoint(x: view.frame.width, y: 0), animated: true)
        updateUnderlinePosition(button: followingButton)
        loadUserList()
    }
    
    // 更新黑色線條的位置
    func updateUnderlinePosition(button: UIButton) {
        underlineView.snp.remakeConstraints { make in
            make.top.equalTo(button.snp.bottom)
            make.leading.equalTo(button)
            make.width.equalTo(button)
            make.height.equalTo(3)
        }
        
        // 動畫過渡效果
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded() // 刷新視圖
        }
    }
    
    // 監聽滑動時的事件
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let buttonWidth = view.frame.width / 2
        
        // 黑色線條的偏移跟隨滑動
        underlineView.snp.remakeConstraints { make in
            make.top.equalTo(followersButton.snp.bottom)
            make.leading.equalTo(view.snp.leading).offset(offsetX / 2) // 重新定義 leading 位置
            make.width.equalTo(buttonWidth)
            make.height.equalTo(3)
        }
        
        // 動態改變按鈕選中狀態
        if offsetX == 0 {
            followersButton.isSelected = true
            followingButton.isSelected = false
        } else if offsetX == view.frame.width {
            followersButton.isSelected = false
            followingButton.isSelected = true
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x == 0 {
            // 展示 Followers
            followersButton.isSelected = true
            followingButton.isSelected = false
            loadUserList() // 加载粉丝数据
        } else {
            // 展示 Following
            followersButton.isSelected = false
            followingButton.isSelected = true
            loadUserList() // 加载关注数据
        }
    }
    
    func loadUserList() {
        guard let userId = userId else { return }
        print("start")
        let userRef = Firestore.firestore().collection("users").document(userId)

        let isShowingFollowers = scrollView.contentOffset.x == 0

        if isShowingFollowers {
            userRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching followers: \(error)")
                    return
                }
                if let data = snapshot?.data(), let followers = data["followers"] as? [String] {
                    self?.followers = followers

                    if followers.isEmpty {
//                        self?.followersTableView.isHidden = true
                        self?.followersPlaceholderLabel.isHidden = false
                    } else {
//                        self?.followersTableView.isHidden = false
                        self?.followersPlaceholderLabel.isHidden = true
                    }
//                    self?.view.layoutIfNeeded()
                    var followersData: [[String: Any]] = []

                    for followerId in followers {
                        FirebaseManager.shared.fetchUserData(userId: followerId) { result in
                            switch result {
                            case .success(let userData):
                                followersData.append(userData)

                                if followersData.count == followers.count {
                                    self?.followersData = followersData
                                    self?.followersTableView.reloadData()
                                }

                            case .failure(let error):
                                print("Error fetching user data: \(error)")
                            }
                        }
                    }
                }
            }
        } else {
            userRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching following: \(error)")
                    return
                }
                if let data = snapshot?.data(), let following = data["following"] as? [String] {
                    self?.following = following

                    if following.isEmpty {
//                        self?.followingTableView.isHidden = true
                        self?.followingPlaceholderLabel.isHidden = false
                    } else {
//                        self?.followingTableView.isHidden = false
                        self?.followingPlaceholderLabel.isHidden = true
                    }
//                    self?.view.layoutIfNeeded()
                    var followingData: [[String: Any]] = []

                    for followingId in following {
                        FirebaseManager.shared.fetchUserData(userId: followingId) { result in
                            switch result {
                            case .success(let userData):
                                followingData.append(userData)

                                if followingData.count == following.count {
                                    self?.followingData = followingData
                                    self?.followingTableView.reloadData()
                                }

                            case .failure(let error):
                                print("Error fetching user data: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
    
    // MARK: - UITableViewDataSource 和 UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == followersTableView {
            return followers.count
        } else {
            return following.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseIdentifier = tableView == followersTableView ? "followerCell" : "followingCell"
        
        // 使用對應的 reuseIdentifier 來 dequeue cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? FollowerFollowingTableViewCell else {
            return UITableViewCell()
        }

        let userData: [String: Any]
        if tableView == followersTableView {
            userData = followersData[indexPath.row]
        } else {
            userData = followingData[indexPath.row]
        }
        
        cell.userNameLabel.text = ""
        cell.avatarImageView.image = UIImage(named: "user-placeholder")

        // 配置 cell 的顯示內容
        cell.userNameLabel.text = userData["userName"] as? String
        if let photoUrlString = userData["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
            cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "user-placeholder"))
        }
        
        cell.ellipsisButton.addTarget(self, action: #selector(didTapEllipsisButton(_:)), for: .touchUpInside)
        cell.ellipsisButton.tag = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUserId = tableView == followersTableView ? followers[indexPath.row] : following[indexPath.row]
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = selectedUserId
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    @objc func didTapEllipsisButton(_ sender: UIButton) {
        let row = sender.tag
        let userData = scrollView.contentOffset.x == 0 ? followersData[row] : followingData[row]
        
        let bottomSheetManager = BottomSheetManager(parentViewController: self)
        
        bottomSheetManager.addActionButton(title: "檢舉用戶", textColor: .red) {
            // 檢舉用戶邏輯
            self.presentReportUserAlert(for: userData)
        }
        
        bottomSheetManager.addActionButton(title: "取消", textColor: .gray) {
            bottomSheetManager.dismissBottomSheet()
        }
        
        bottomSheetManager.setupBottomSheet()
        bottomSheetManager.showBottomSheet()
    }

    // 示例：显示檢舉用戶的 alert
    func presentReportUserAlert(for userData: [String: Any]) {
        let userName = userData["userName"] as? String ?? "該用戶"
        let alertController = UIAlertController(title: "檢舉用戶", message: "你確定要檢舉 \(userName) 嗎？", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: "檢舉", style: .destructive) { _ in
            print("檢舉 \(userName)")
        }
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
