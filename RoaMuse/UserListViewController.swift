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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupButtons()
        setupUnderlineView()
        setupScrollView()
        setupTableViews()
        
        if isShowingFollowers {
            // 如果顯示粉絲，將 ScrollView 設置到最左邊
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            updateUnderlinePosition(button: followersButton)
        } else {
            // 如果顯示關注，將 ScrollView 設置到最右邊
            scrollView.setContentOffset(CGPoint(x: view.frame.width, y: 0), animated: false)
            updateUnderlinePosition(button: followingButton)
        }
        
        loadUserList()
    }
    
    // 設置自定義按鈕
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
    
    // 設置底部黑色線條
    func setupUnderlineView() {
        underlineView.backgroundColor = .black
        view.addSubview(underlineView)
        
        // 初始時黑色線條位於粉絲按鈕下方
        underlineView.snp.makeConstraints { make in
            make.top.equalTo(followersButton.snp.bottom)
            make.leading.equalTo(followersButton) // 確保初始leading綁定到followersButton
            make.width.equalTo(followersButton)
            make.height.equalTo(3)
        }
    }
    
    // 設置 UIScrollView
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
        followersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "followerCell")
        scrollView.addSubview(followersTableView)
        
        followersTableView.snp.makeConstraints { make in
            make.leading.equalTo(scrollView.snp.leading)
            make.top.equalTo(scrollView.snp.top)
            make.width.equalTo(view.frame.width)
            make.height.equalTo(scrollView.snp.height)
        }
        
        followingTableView.delegate = self
        followingTableView.dataSource = self
        followingTableView.register(UITableViewCell.self, forCellReuseIdentifier: "followingCell")
        scrollView.addSubview(followingTableView)
        
        followingTableView.snp.makeConstraints { make in
            make.leading.equalTo(followersTableView.snp.trailing)
            make.top.equalTo(scrollView.snp.top)
            make.width.equalTo(view.frame.width)
            make.height.equalTo(scrollView.snp.height)
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
                    
//                    for followerId in followers {
//                        FirebaseManager.shared.fetchUserData(userId: followerId) { result in
//                            switch result {
//
//                            }
//                        }
//                    }
                    
                    self?.followersTableView.reloadData()
                }
            }
        } else {
            print("follow")
            userRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching following: \(error)")
                    return
                }
                if let data = snapshot?.data(), let following = data["following"] as? [String] {
                    self?.following = following
                    print("=====",following)
                    self?.followingTableView.reloadData()
                }
            }
        }
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
        if tableView == followersTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "followerCell", for: indexPath)
            cell.textLabel?.text = followers[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "followingCell", for: indexPath)
            cell.textLabel?.text = following[indexPath.row]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUserId = tableView == followersTableView ? followers[indexPath.row] : following[indexPath.row]
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = selectedUserId
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
}
