//
//  PostsTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import FirebaseFirestore
import SnapKit

class PostsTableViewCell: UITableViewCell {
    
    var titleLabel = UILabel()
    var authorLabel = UILabel()
    var timeLabel = UILabel()
    var contentLabel = UILabel()
    let collectButton = UIButton(type: .system)
    let likeButton = UIButton(type: .system) // 新增的 likeButton
    let commentButton = UIButton(type: .system) // 新增的 commentButton
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: "homeCell")
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupUI() {
        self.addSubview(titleLabel)
        self.addSubview(authorLabel)
        self.addSubview(timeLabel)
        self.addSubview(contentLabel)
        self.contentView.addSubview(collectButton)
        self.contentView.addSubview(likeButton) // 加入 likeButton
        self.contentView.addSubview(commentButton) // 加入 commentButton
        
        // 設置標題、作者、時間、內容的約束
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(20)
            make.bottom.equalTo(self.snp.centerY).offset(-20)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(authorLabel.snp.trailing).offset(10)
            make.top.equalTo(authorLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(self).offset(-20)
            make.top.equalTo(authorLabel.snp.bottom).offset(10)
        }
        
        // 設置收藏按鈕的約束
        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.width.height.equalTo(35)
        }
        
        // 設置 likeButton 的約束
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(30)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        // 設置 commentButton 的約束
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(30)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        // 設置按鈕圖片
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .selected)
        likeButton.tintColor = UIColor.systemBlue
        
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = UIColor.systemGreen
        
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor.systemPink
        
        // 其他標題、內容的屬性設定
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        contentLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        
        collectButton.isEnabled = true
    }
}

// 儲存文章收藏
func updateUserCollections(userId: String) {
    // 獲取 Firestore 的引用
    let db = Firestore.firestore()
    // 指定用戶文檔的路徑
    let userRef = db.collection("user").document(userId)
    // 使用 `updateData` 方法只更新 bookmarkPost 字段
    userRef.updateData([
        "bookmarkPost": [""]
    ]) { error in
        if let error = error {
            print("更新收藏數量失敗：\(error.localizedDescription)")
        } else {
            print("收藏數量更新成功！")
        }
    }
}
