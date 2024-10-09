//
//  ChatMessageCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit

class ChatMessageCell: UITableViewCell {
    
    let messageLabel = UILabel()
    let messageBubble = UIView()
    let avatarImageView = UIImageView()
    let timestampLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        
        messageLabel.numberOfLines = 0  // 允许多行
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageBubble.layer.cornerRadius = 16
        messageBubble.clipsToBounds = true
        
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        
        timestampLabel.font = UIFont.systemFont(ofSize: 12)
        timestampLabel.textColor = .lightGray
        
        contentView.addSubview(messageBubble)
        contentView.addSubview(messageLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(timestampLabel)
        
        // 配置 messageBubble 的最大宽度
        messageBubble.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.lessThanOrEqualTo(250) // 设置消息气泡的最大宽度为 250
        }
        
        // messageLabel 设置与 messageBubble 的边距
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(messageBubble).inset(10)
        }
        
        // 头像的约束设置
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.bottom.equalTo(messageBubble)
        }
        
        // 时间戳的约束设置
        timestampLabel.snp.makeConstraints { make in
            make.top.equalTo(messageBubble.snp.bottom).offset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 根据消息内容设置气泡颜色和位置
    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        let isFromCurrentUser = message.isFromCurrentUser
        
        // 根据是否是当前用户调整布局
        if isFromCurrentUser {
            messageBubble.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            
            messageBubble.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.width.lessThanOrEqualTo(250)  // 设置宽度限制
            }
            
            avatarImageView.isHidden = true
            timestampLabel.snp.remakeConstraints { make in
                make.top.equalTo(messageBubble.snp.bottom).offset(4)
                make.right.equalTo(messageBubble.snp.right)
            }
        } else {
            messageBubble.backgroundColor = .systemGray5
            messageLabel.textColor = .black
            avatarImageView.image = UIImage(named: "avatar_placeholder") // 对方的头像
            
            messageBubble.snp.remakeConstraints { make in
                make.left.equalTo(avatarImageView.snp.right).offset(8)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.width.lessThanOrEqualTo(250)  // 设置宽度限制
            }
            
            avatarImageView.isHidden = false
            timestampLabel.snp.remakeConstraints { make in
                make.top.equalTo(messageBubble.snp.bottom).offset(4)
                make.left.equalTo(messageBubble.snp.left)
            }
        }
    }
}
