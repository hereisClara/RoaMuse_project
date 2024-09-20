import Foundation
import UIKit
import SnapKit

class ArticleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var authorId = String()
    var postId = String()
    var bookmarkAccounts = [String]()
    
    let tableView = UITableView()
    
    // 假資料
    var articleTitle = "文章標題"
    var articleAuthor = "作者名稱"
    var articleContent = "這是一篇測試文章的內容，這裡是比較長的測試文章，用來測試表格和表頭自適應大小的效果。這是一篇測試文章的內容，這裡是比較長的測試文章，用來測試表格和表頭自適應大小的效果。"
    var articleDate = "2024年9月20日"
    var comments = [
        ["username": "使用者1", "content": "這是第一則留言", "createdAt": "2024-09-20"],
        ["username": "使用者2", "content": "這是第二則留言", "createdAt": "2024-09-21"]
    ]
    
    var isBookmarked = false
    let collectButton = UIButton(type: .system)
    let likeButton = UIButton(type: .system)
    let commentButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 設置收藏按鈕的初始狀態
        checkBookmarkStatus()
        
        setupTableView()
    }
    
    // 設置 TableView
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // 允許自動調整行高
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        
        // 允許表頭自動調整大小
        let headerView = createHeaderView()
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = headerHeight
        headerView.frame = frame
        tableView.tableHeaderView = headerView
        
        // 註冊 cell
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.estimatedRowHeight = 100  // 預估行高
        tableView.rowHeight = UITableView.automaticDimension  // 自適應行高
        
        // 使用 SnapKit 設置 TableView
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // 創建表頭視圖 (header)
    func createHeaderView() -> UIView {
        let headerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = articleTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        let authorLabel = UILabel()
        authorLabel.text = "作者: \(articleAuthor)"
        authorLabel.font = UIFont.systemFont(ofSize: 16)
        authorLabel.numberOfLines = 0
        headerView.addSubview(authorLabel)
        
        let contentLabel = UILabel()
        contentLabel.text = articleContent
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        contentLabel.numberOfLines = 0
        headerView.addSubview(contentLabel)
        
        let dateLabel = UILabel()
        dateLabel.text = articleDate
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .gray
        dateLabel.numberOfLines = 0
        headerView.addSubview(dateLabel)
        
        // 設置按讚按鈕
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .selected)
        likeButton.tintColor = UIColor.systemBlue
        likeButton.addTarget(self, action: #selector(didTapLikeButton(_:)), for: .touchUpInside)
        headerView.addSubview(likeButton)
        
        // 設置留言按鈕
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = UIColor.systemGreen
        commentButton.addTarget(self, action: #selector(didTapCommentButton(_:)), for: .touchUpInside)
        headerView.addSubview(commentButton)
        
        // 設置收藏按鈕
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor.systemPink
        collectButton.addTarget(self, action: #selector(didTapCollectButton(_:)), for: .touchUpInside)
        headerView.addSubview(collectButton)
        
        let bookmarkCountLabel = UILabel()
        bookmarkCountLabel.text = String(bookmarkAccounts.count)
        bookmarkCountLabel.font = UIFont.systemFont(ofSize: 14)
        headerView.addSubview(bookmarkCountLabel)
        
        // 使用 SnapKit 進行佈局
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView).offset(16)
            make.leading.equalTo(headerView).offset(16)
            make.trailing.equalTo(headerView).offset(-16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
        }
        
        // 設置按鈕們的佈局
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.equalTo(titleLabel)
            make.width.height.equalTo(30)
        }
        
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(40)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(40)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
            make.bottom.equalTo(headerView).offset(-16) // 確保 header 自適應大小
        }
        
        bookmarkCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(collectButton.snp.trailing).offset(10)
            make.centerY.equalTo(collectButton)
        }
        
        return headerView
    }
    
    // 檢查文章是否已被收藏，並更新收藏按鈕狀態
    func checkBookmarkStatus() {
        FirebaseManager.shared.isContentBookmarked(forUserId: authorId, id: postId) { [weak self] isBookmarked in
            guard let self = self else { return }
            self.collectButton.isSelected = isBookmarked
        }
    }
    
    // 按讚按鈕事件處理
    @objc func didTapLikeButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            print("按讚成功")
        } else {
            print("取消按讚")
        }
    }
    
    // 留言按鈕事件處理
    @objc func didTapCommentButton(_ sender: UIButton) {
        print("跳轉到留言區")
        // 可在此處跳轉到留言區
    }
    
    // 收藏按鈕事件處理
    @objc func didTapCollectButton(_ sender: UIButton) {
        let userId = authorId  // 假設為當前使用者ID
        let postId = postId    // 假設文章的ID
        
        // 使用 FirebaseManager 檢查是否已收藏該文章
        FirebaseManager.shared.isContentBookmarked(forUserId: userId, id: postId) { [weak self] isBookmarked in
            guard let self = self else { return }
            if isBookmarked {
                // 如果已經收藏，則執行取消收藏操作
                FirebaseManager.shared.removePostBookmark(forUserId: userId, postId: postId) { success in
                    if success {
                        print("取消收藏成功")
                        self.collectButton.isSelected = false
                    } else {
                        print("取消收藏失敗")
                    }
                    self.tableView.reloadData()
                }
            } else {
                // 如果尚未收藏，則執行收藏操作
                FirebaseManager.shared.updateUserCollections(userId: userId, id: postId) { success in
                    if success {
                        print("收藏成功")
                        self.collectButton.isSelected = true
                    } else {
                        print("收藏失敗")
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // UITableViewDataSource - 設定 cell 的數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count  // 返回留言數量
    }
    
    // UITableViewDataSource - 設定每個 cell 的樣式
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        
        let comment = comments[indexPath.row]
        let username = comment["username"] as? String ?? "未知使用者"
        let content = comment["content"] as? String ?? "無內容"
        let createdAt = comment["createdAt"] as? String ?? "未知時間"
        
        cell.configure(username: username, content: content, createdAt: createdAt)
        return cell
    }

    
    // UITableViewDelegate - 設定自動調整行高
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
