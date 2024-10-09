//
//  UserListViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import UIKit
import FirebaseFirestore

class UserListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var userId: String?
    var isShowingFollowers: Bool = true // 判断是显示粉丝还是关注
    var users: [String] = [] // 存储粉丝或关注的用户列表
    
    let segmentedControl = UISegmentedControl(items: ["Followers", "Following"])
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupSegmentedControl()
        setupTableView()
        loadUserList()
    }
    
    // 设置 UISegmentedControl
    func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = isShowingFollowers ? 0 : 1
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalTo(view)
            make.width.equalTo(200)
        }
    }
    
    // 设置 UITableView
    func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // 加载粉丝或关注列表数据
    func loadUserList() {
        guard let userId = userId else { return }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        if isShowingFollowers {
            // 获取粉丝数据
            userRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching followers: \(error)")
                    return
                }
                if let data = snapshot?.data(), let followers = data["followers"] as? [String] {
                    self?.users = followers
                    self?.tableView.reloadData()
                }
            }
        } else {
            // 获取关注数据
            userRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching following: \(error)")
                    return
                }
                if let data = snapshot?.data(), let following = data["following"] as? [String] {
                    self?.users = following
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    // 根据选择的 segment 切换内容
    @objc func segmentChanged() {
        isShowingFollowers = segmentedControl.selectedSegmentIndex == 0
        loadUserList()
    }
    
    // MARK: - UITableViewDataSource 和 UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let userId = users[indexPath.row]
        cell.selectionStyle = .none
        
        FirebaseManager.shared.fetchUserData(userId: userId) { result in
                switch result {
                case .success(let data):
                    if let userName = data["userName"] as? String {
                        DispatchQueue.main.async {
                            cell.textLabel?.text = userName
                        }
                    } else {
                        DispatchQueue.main.async {
                            cell.textLabel?.text = "Unknown User"
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        cell.textLabel?.text = "Error: \(error.localizedDescription)"
                    }
                }
            }
            
            return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 点击某个粉丝或关注用户时跳转到其个人页面
        let selectedUserId = users[indexPath.row]
        
        let userProfileVC = UserProfileViewController()
        userProfileVC.userId = selectedUserId
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
}
