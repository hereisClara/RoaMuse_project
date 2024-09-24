import Foundation
import UIKit
import SnapKit
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore
import Kingfisher

class UserProfileViewController: UIViewController {

    var userId: String?

    let tableView = UITableView()
    let userNameLabel = UILabel()
    let awardsLabel = UILabel()
    var posts: [[String: Any]] = []

    let avatarImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        setupTableView()
        setupUI()

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

    func setupUI() {
        let headerView = UIView()
        headerView.backgroundColor = .lightGray
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 120)

        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(userNameLabel)

        awardsLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        headerView.addSubview(awardsLabel)

        avatarImageView.backgroundColor = .blue
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        headerView.addSubview(avatarImageView)

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

        tableView.tableHeaderView = headerView
    }

    func loadAvatarImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"), options: [
            .transition(.fade(0.2)),
            .cacheOriginalImage
        ])
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
        cell.selectionStyle = .none

        return cell
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
