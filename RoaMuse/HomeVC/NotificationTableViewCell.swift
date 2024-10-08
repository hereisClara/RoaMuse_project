//
//  NotificationTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/7.
//

import Foundation
import UIKit
import Kingfisher
import FirebaseCore
import FirebaseFirestore

class NotificationTableViewCell: UITableViewCell {
    
    let avatarImageView = UIImageView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        // 配置頭像
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.layer.masksToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(named: "avatar_placeholder")
        contentView.addSubview(avatarImageView)
        
        // 配置標題
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        titleLabel.textColor = .black
        contentView.addSubview(titleLabel)
        
        // 配置訊息
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 2
        contentView.addSubview(messageLabel)
        
        // 配置時間
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = .gray
        contentView.addSubview(dateLabel)
        
        // 使用 SnapKit 佈局
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.leading.equalTo(contentView).offset(16)
            make.centerY.equalTo(contentView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(8)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalTo(contentView).offset(-16)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(4)
            make.leading.equalTo(messageLabel)
            make.bottom.equalTo(contentView).offset(-8)
        }
    }
    
    func configure(with notification: Notification, avatarUrl: String?) {
        titleLabel.text = notification.title ?? "通知"
        messageLabel.text = notification.message ?? "你有一則新通知"
        
        // 使用 DateManager 格式化日期
        dateLabel.text = DateManager.shared.formatDate(notification.createdAt)
        
        // 設置頭像
        if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
            avatarImageView.kf.setImage(with: url, placeholder: UIImage(named: "user-placeholder"))
        } else {
            avatarImageView.image = UIImage(named: "user-placeholder")
        }
    }
}
