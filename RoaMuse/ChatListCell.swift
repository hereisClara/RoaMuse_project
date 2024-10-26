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
    let lastMessageTimeLabel = UILabel() // 新增的時間顯示 Label

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(lastMessageTimeLabel) // 添加到視圖中
        
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
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
        
        lastMessageTimeLabel.font = UIFont.systemFont(ofSize: 12)
        lastMessageTimeLabel.textColor = .lightGray
        lastMessageTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).offset(-10)
            make.top.equalTo(contentView).offset(15)
        }
    }
    
    func configure(with chat: Chat) {
        userNameLabel.text = chat.userName
        lastMessageLabel.text = chat.lastMessage
        
        // 格式化時間顯示
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        lastMessageTimeLabel.text = dateFormatter.string(from: chat.lastMessageTime)
        
        if let url = URL(string: chat.profileImage) {
            profileImageView.kf.setImage(with: url)
        } else {
            profileImageView.image = UIImage(named: "user-placeholder")
        }
    }
}
