//
//  CommentTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/20.
//

import Foundation
import UIKit
import SnapKit

class CommentTableViewCell: UITableViewCell {
    
    // 定義 username, content 和 createdAt 的 UILabel
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        label.numberOfLines = 1
        label.textColor = .deepBlue
        return label
    }()
    
    let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        label.numberOfLines = 0  // 支援多行
        label.lineSpacing = 3
        label.lineBreakMode = .byWordWrapping
        label.textColor = .darkGray
        return label
    }()
    
    let createdAtLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.numberOfLines = 1
        return label
    }()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // 將子視圖添加到 contentView 中
        contentView.addSubview(usernameLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(createdAtLabel)
        contentView.addSubview(avatarImageView)
        
        // 使用 SnapKit 設置約束條件
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(8)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            make.trailing.equalTo(contentView).offset(-16)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(4)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            make.trailing.equalTo(contentView).offset(-16)
            make.bottom.equalTo(createdAtLabel).offset(-16)
        }
        
        createdAtLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(4)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            make.trailing.equalTo(contentView).offset(-16)
            make.bottom.equalTo(contentView).offset(-8) // 確保自適應
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.leading.top.equalTo(contentView).offset(12)
            make.width.height.equalTo(30)
        }
        
        avatarImageView.layer.cornerRadius = 15
        
        usernameLabel.text = "username"
        contentLabel.text = "content"
        createdAtLabel.text = "createdAt"
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
