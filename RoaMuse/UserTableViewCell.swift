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
    
    let collectButton = UIButton()
    let likeButton = UIButton() // 新增的 likeButton
    let commentButton = UIButton() // 新增的 commentButton
    let titleLabel = UILabel()
    let likeCountLabel = UILabel()
    let bookmarkCountLabel = UILabel()
    let contentLabel = UILabel()
    let avatarImageView = UIImageView()
    let dateLabel = UILabel()
    let moreButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width * 0.5
        avatarImageView.layer.masksToBounds = true
    }
    
    // 設置 cell 內的內容
    func setupCell() {
        
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        avatarImageView.backgroundColor = .blue
        
        self.addSubview(moreButton)
        self.addSubview(titleLabel)
        self.addSubview(dateLabel)
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
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView)
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.leading.equalTo(self).offset(16)
            make.trailing.equalTo(self).offset(-16)
            make.height.equalTo(80)
        }
        
        likeButton.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView).offset(10)
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.width.height.equalTo(20)
        }
        
        commentButton.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(60)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(20)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(commentButton.snp.trailing).offset(60)
            make.centerY.equalTo(likeButton)
            make.width.height.equalTo(20)
        }
        
        bookmarkCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(collectButton.snp.trailing).offset(10)
            make.centerY.equalTo(collectButton)
        }
        
        likeCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(10)
            make.centerY.equalTo(likeButton)
        }
        
        moreButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(self).offset(-16)
            make.width.height.equalTo(20)
        }
        
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .deepBlue
        
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        likeCountLabel.textColor = .deepBlue
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true

        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.textColor = .darkGray
        
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .deepBlue
        
        dateLabel.textColor = .gray
        
        // 設置按鈕圖片
        likeButton.setImage(UIImage(named: "normal_heart"), for: .normal)
        likeButton.setImage(UIImage(named: "selected_heart"), for: .selected)
        
        commentButton.setImage(UIImage(named: "normal_comment"), for: .normal)

        collectButton.setImage(UIImage(named: "normal_bookmark"), for: .normal)
        collectButton.setImage(UIImage(named: "selected_bookmark"), for: .selected)
        
        dateLabel.font = UIFont.systemFont(ofSize: 14)
    }
}
