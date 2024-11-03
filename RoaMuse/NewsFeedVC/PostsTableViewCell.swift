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
    
    let likeCountLabel = UILabel()
    let bookmarkCountLabel = UILabel()
    
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
        self.addSubview(bookmarkCountLabel)
        self.addSubview(likeCountLabel)
        self.contentView.addSubview(collectButton)
        self.contentView.addSubview(likeButton)
        self.contentView.addSubview(commentButton) 
        
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
        
        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.width.height.equalTo(35)
        }
        
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(60)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(60)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        bookmarkCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(collectButton.snp.trailing).offset(10)
            make.centerY.equalTo(collectButton)
        }
        
        likeCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(10)
            make.centerY.equalTo(likeButton)
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
        
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        contentLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        
        collectButton.isEnabled = true
    }
}

func updateUserCollections(userId: String) {
    let db = Firestore.firestore()
    let userRef = db.collection("user").document(userId)
    userRef.updateData([
        "bookmarkPost": [""]
    ]) { error in
        if let error = error {
            print("更新收藏數量失敗：\(error.localizedDescription)")
        }
    }
}
