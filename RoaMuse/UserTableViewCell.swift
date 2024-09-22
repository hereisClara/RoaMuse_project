//
//  UserTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/19.
//

import Foundation
import UIKit
import SnapKit

class UserTableViewCell: UITableViewCell {
    
    let collectButton = UIButton(type: .system)
    let likeButton = UIButton(type: .system) // 新增的 likeButton
    let commentButton = UIButton(type: .system) // 新增的 commentButton
    let titleLabel = UILabel()
    let likeCountLabel = UILabel()
    let bookmarkCountLabel = UILabel()
    let contentLabel = UILabel()
    let avatarImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 設置 cell 內的內容
    func setupCell() {
        
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        avatarImageView.backgroundColor = .blue
        
        self.addSubview(titleLabel)
        self.addSubview(contentLabel)
        self.addSubview(avatarImageView)
        self.addSubview(bookmarkCountLabel)
        self.addSubview(likeCountLabel)
        self.contentView.addSubview(collectButton)
        self.contentView.addSubview(likeButton) // 加入 likeButton
        self.contentView.addSubview(commentButton) // 加入 commentButton
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(30)
            make.leading.equalTo(self).offset(15)
            make.width.height.equalTo(50)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(15)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView)
            make.top.equalTo(avatarImageView.snp.bottom).offset(10)
            make.height.equalTo(80)
        }
        
        // 設置收藏按鈕的約束
        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView)
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.width.height.equalTo(35)
        }
        
        // 設置 likeButton 的約束
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(60)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(30)
        }
        
        // 設置 commentButton 的約束
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
        
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width * 0.9
        
        // 設置按鈕圖片
        likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .selected)
        likeButton.tintColor = UIColor.systemBlue
        
        
        commentButton.setImage(UIImage(systemName: "message"), for: .normal)
        commentButton.tintColor = UIColor.systemGreen
        
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor.systemPink
    }
}
