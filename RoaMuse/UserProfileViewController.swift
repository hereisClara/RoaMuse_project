import Foundation
import UIKit
import SnapKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher
import MJRefresh

class UserProfileViewController: UIViewController {

    var userId: String?

    let tableView = UITableView()
    let userNameLabel = UILabel()
    let awardsLabel = UILabel()
    let fansLabel = UILabel()
    var posts: [[String: Any]] = []
    var followButton = UIButton()

    let avatarImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        checkIfFollowing()
        setupTableView()
        setupUI()
        setupRefreshControl()
        guard let userId = userId else {
            print("無法獲取 userId")
            return
        }

        // 從 Firebase 獲取用戶資料
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userNameLabel.text = userName
                }
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
                if let followers = data["followers"] as? [String] {
                    self?.fansLabel.text = "粉絲人數：\(String(followers.count))"
                }
                
                FirebaseManager.shared.countCompletedPlaces(userId: userId) { totalPlaces in
                    self?.awardsLabel.text = "打開卡片：\(String(totalPlaces))張"
                }
            case .failure(let error):
                print("獲取用戶資料失敗: \(error.localizedDescription)")
            }
        }

        // 加載用戶貼文
        loadUserPosts()
    }
    
    func setupRefreshControl() {
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.reloadAllData()  // 在下拉刷新時重新加載所有資料
        })
    }
    
    func reloadAllData() {
        guard let userId = userId else {
            self.tableView.mj_header?.endRefreshing() // 保證刷新結束
            return
        }

        // 重新加載用戶資料
        FirebaseManager.shared.fetchUserData(userId: userId) { [weak self] result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self?.userNameLabel.text = userName
                }
                // 顯示 avatar 圖片
                if let avatarUrl = data["photo"] as? String {
                    self?.loadAvatarImage(from: avatarUrl)
                }
                
                if let followers = data["followers"] as? [String] {
                    self?.fansLabel.text = "粉絲人數：\(String(followers.count))"
                }
                
            case .failure(let error):
                print("Error fetching user data: \(error.localizedDescription)")
            }
            
            FirebaseManager.shared.countCompletedPlaces(userId: userId) { totalPlaces in
                self?.awardsLabel.text = "打開卡片：\(String(totalPlaces))張"
            }
        }
        
        // 重新加載用戶貼文
        loadUserPosts()
        
        // 結束刷新
        DispatchQueue.main.async {
            self.tableView.mj_header?.endRefreshing()
        }
    }

    func setupUI() {
        let headerView = UIView()
        headerView.backgroundColor = .lightGray
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 120)

        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(userNameLabel)

        awardsLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        headerView.addSubview(awardsLabel)
        
        followButton.setTitle("追蹤", for: .normal)
        followButton.setTitle("已追蹤", for: .selected)
        followButton.setTitleColor(.white, for: .normal)
        followButton.backgroundColor = .clear
        followButton.layer.borderColor = UIColor.white.cgColor
        followButton.layer.borderWidth = 1
        followButton.layer.cornerRadius = 10
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        followButton.addTarget(self, action: #selector(handleFollowButtonTapped), for: .touchUpInside)
        headerView.addSubview(followButton)

        avatarImageView.backgroundColor = .blue
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)
        
        fansLabel.text = "粉絲人數：0"
        fansLabel.font = UIFont.systemFont(ofSize: 16)
        headerView.addSubview(fansLabel)
        
        fansLabel.snp.makeConstraints { make in
            make.leading.equalTo(awardsLabel)
            make.top.equalTo(awardsLabel.snp.bottom).offset(8)
        }

        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
        }

        awardsLabel.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(8)
            make.leading.equalTo(userNameLabel)
        }

        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(70)
            make.centerY.equalTo(headerView)
            make.leading.equalTo(headerView).offset(15)
        }
        
        followButton.snp.makeConstraints { make in
            make.trailing.equalTo(headerView).offset(-16)
            make.centerY.equalTo(userNameLabel)
            make.width.equalTo(50)
        }

        tableView.tableHeaderView = headerView
    }

    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"), options: [
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ])
    }
    
    @objc func handleFollowButtonTapped() {
        guard let followedUserId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId 或當前用戶 ID")
            return
        }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        let followedUserRef = Firestore.firestore().collection("users").document(followedUserId)
        
        if followButton.isSelected {
            // 取消追蹤
            currentUserRef.updateData([
                "following": FieldValue.arrayRemove([followedUserId])
            ]) { error in
                if let error = error {
                    print("取消追蹤失敗: \(error.localizedDescription)")
                } else {
                    print("取消追蹤成功")
                    // 從被追蹤者的 followers 中移除當前用戶
                    followedUserRef.updateData([
                        "followers": FieldValue.arrayRemove([currentUserId])
                    ]) { error in
                        if let error = error {
                            print("從被追蹤者 followers 移除失敗: \(error.localizedDescription)")
                        } else {
                            print("已從被追蹤者的 followers 中移除")
                            DispatchQueue.main.async {
                                self.followButton.isSelected = false
                            }
                        }
                    }
                }
            }
        } else {
            // 追蹤
            currentUserRef.updateData([
                "following": FieldValue.arrayUnion([followedUserId])
            ]) { error in
                if let error = error {
                    print("追蹤失敗: \(error.localizedDescription)")
                } else {
                    print("追蹤成功")
                    // 同時在被追蹤者的 followers 中加入當前用戶
                    followedUserRef.updateData([
                        "followers": FieldValue.arrayUnion([currentUserId])
                    ]) { error in
                        if let error = error {
                            print("將當前用戶添加到 followers 失敗: \(error.localizedDescription)")
                        } else {
                            print("已添加當前用戶到被追蹤者的 followers")
                            DispatchQueue.main.async {
                                self.followButton.isSelected = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkIfFollowing() {
        guard let userId = userId, let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("無法獲取 userId 或當前用戶 ID")
            return
        }
        
        let currentUserRef = Firestore.firestore().collection("users").document(currentUserId)
        currentUserRef.getDocument { snapshot, error in
            if let error = error {
                print("檢查追蹤狀態失敗: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(), let following = data["following"] as? [String] else {
                print("無法獲取追蹤數據")
                return
            }
            
            DispatchQueue.main.async {
                self.followButton.isSelected = following.contains(userId)
            }
        }
    }
}

extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func setupTableView() {
        view.addSubview(tableView)

        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "userCell")

        tableView.delegate = self
        tableView.dataSource = self

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserTableViewCell

        guard let cell = cell else { return UITableViewCell() }

        let post = posts[indexPath.row]
        cell.titleLabel.text = post["title"] as? String ?? "無標題"
        cell.contentLabel.text = post["content"] as? String ?? "無內容"
        
        FirebaseManager.shared.fetchUserData(userId: self.userId ?? "") { result in
            switch result {
            case .success(let data):
                if let photoUrlString = data["photo"] as? String, let photoUrl = URL(string: photoUrlString) {
                    // 使用 Kingfisher 加載圖片到 avatarImageView
                    DispatchQueue.main.async {
                        cell.avatarImageView.kf.setImage(with: photoUrl, placeholder: UIImage(named: "placeholder"))
                    }
                }
            case .failure(let error):
                print("加載用戶大頭貼失敗: \(error.localizedDescription)")
            }
        }
        
        // 檢查收藏狀態
        FirebaseManager.shared.isContentBookmarked(forUserId: userId ?? "", id: post["id"] as? String ?? "") { isBookmarked in
            cell.collectButton.isSelected = isBookmarked
        }
        
        cell.selectionStyle = .none

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        let articleVC = ArticleViewController()
        
        FirebaseManager.shared.fetchUserNameByUserId(userId: post["userId"] as? String ?? "") { userName in
            if let userName = userName {
                articleVC.articleAuthor = userName
                articleVC.articleTitle = post["title"] as? String ?? "無標題"
                articleVC.articleContent = post["content"] as? String ?? "無內容"
                articleVC.tripId = post["tripId"] as? String ?? ""
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }

    func loadUserPosts() {
        guard let userId = userId else { return }

        FirebaseManager.shared.loadSpecifyUserPost(forUserId: userId) { [weak self] postsArray in
            guard let self = self else { return }
            self.posts = postsArray.sorted(by: { (post1, post2) -> Bool in
                if let createdAt1 = post1["createdAt"] as? Timestamp, let createdAt2 = post2["createdAt"] as? Timestamp {
                    return createdAt1.dateValue() > createdAt2.dateValue()
                }
                return false
            })
            self.tableView.reloadData()
        }
    }
}
