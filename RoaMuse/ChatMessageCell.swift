//
//  ChatMessageCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit
import SnapKit
import Kingfisher

class ChatMessageCell: UITableViewCell {
    
    let messageLabel = UILabel()
    let messageBubble = UIView()
    let avatarImageView = UIImageView()
    let timestampLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        messageBubble.layer.cornerRadius = 16
        messageBubble.clipsToBounds = true
        
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        
        timestampLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 12)
        timestampLabel.textColor = .lightGray
        
        contentView.addSubview(messageBubble)
        contentView.addSubview(messageLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(timestampLabel)
        
        messageBubble.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.lessThanOrEqualTo(250)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(messageBubble).inset(10)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.bottom.equalTo(messageBubble)
            make.left.equalToSuperview().offset(16)
        }
        
        timestampLabel.snp.makeConstraints { make in
            make.bottom.equalTo(messageBubble.snp.bottom)
            make.width.lessThanOrEqualTo(80)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with message: ChatMessage, profileImageUrl: String) {
        messageLabel.text = message.text
        let isFromCurrentUser = message.isFromCurrentUser
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timestampLabel.text = dateFormatter.string(from: message.timestamp)

        if isFromCurrentUser {
            messageBubble.backgroundColor = .deepBlue
            messageLabel.textColor = .backgroundGray
            
            messageBubble.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.width.lessThanOrEqualTo(250)
            }
            
            avatarImageView.isHidden = true
            
            timestampLabel.snp.remakeConstraints { make in
                make.bottom.equalTo(messageBubble.snp.bottom)
                make.trailing.equalTo(messageBubble.snp.leading).offset(-8)
            }
        } else {
            messageBubble.backgroundColor = .white
            messageLabel.textColor = .deepBlue
//            avatarImageView.image = UIImage(named: "user-placeholder")
            avatarImageView.kf.setImage(with: URL(string: profileImageUrl), placeholder: UIImage(named: "user-placeholder"))
            
            messageBubble.snp.remakeConstraints { make in
                make.left.equalTo(avatarImageView.snp.right).offset(8)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.width.lessThanOrEqualTo(250)
            }
            
            avatarImageView.isHidden = false
            avatarImageView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.bottom.equalTo(messageBubble)
                make.width.height.equalTo(40)
            }
            
            timestampLabel.snp.remakeConstraints { make in
                make.bottom.equalTo(messageBubble.snp.bottom)
                make.leading.equalTo(messageBubble.snp.trailing).offset(8)
            }
        }
    }
}
