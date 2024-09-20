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
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()
    
    let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0  // 支援多行
        return label
    }()
    
    let createdAtLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        label.numberOfLines = 1
        return label
    }()
    
    // 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // 將子視圖添加到 contentView 中
        contentView.addSubview(usernameLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(createdAtLabel)
        
        // 使用 SnapKit 設置約束條件
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(8)
            make.leading.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(4)
            make.leading.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
        }
        
        createdAtLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(4)
            make.leading.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
            make.bottom.equalTo(contentView).offset(-8) // 確保自適應
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 設置 cell 的數據
    func configure(username: String, content: String, createdAt: String) {
        usernameLabel.text = username
        contentLabel.text = content
        createdAtLabel.text = createdAt
    }
}
