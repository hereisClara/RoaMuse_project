//
//  ChatListCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit

class ChatListCell: UITableViewCell {

    let profileImageView = UIImageView()
    let userNameLabel = UILabel()
    let lastMessageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        // 添加子视图
        contentView.addSubview(profileImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(lastMessageLabel)
        
        // 设置头像为圆形
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        // 布局
        profileImageView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(10)
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(60)
        }
        
        userNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        userNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(10)
            make.top.equalTo(contentView).offset(15)
            make.trailing.equalTo(contentView).offset(-10)
        }
        
        lastMessageLabel.font = UIFont.systemFont(ofSize: 14)
        lastMessageLabel.textColor = .gray
        lastMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(10)
            make.top.equalTo(userNameLabel.snp.bottom).offset(5)
            make.trailing.equalTo(contentView).offset(-10)
        }
    }
    
    // 配置 Cell
    func configure(with chat: Chat) {
        userNameLabel.text = chat.userName
        lastMessageLabel.text = chat.lastMessage
        profileImageView.image = UIImage(named: chat.profileImage)  // 假设用本地图片，实际可用 URL 加载
    }
}
