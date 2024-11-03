//
//  FollowerFollowingTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/11.
//

import Foundation
import UIKit
import SnapKit

class FollowerFollowingTableViewCell: UITableViewCell {
    
    let avatarImageView = UIImageView()
    let userNameLabel = UILabel()
    let unfollowButton = UIButton(type: .system)
    let ellipsisButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.addSubview(avatarImageView)
        
        userNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        userNameLabel.textColor = .black
        contentView.addSubview(userNameLabel)
        
//        unfollowButton.setTitle("取消追蹤", for: .normal)
//        unfollowButton.setTitleColor(.red, for: .normal)
//        unfollowButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        unfollowButton.layer.cornerRadius = 8
//        unfollowButton.layer.borderWidth = 1
//        unfollowButton.layer.borderColor = UIColor.red.cgColor
//        contentView.addSubview(unfollowButton)
        
        ellipsisButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        ellipsisButton.tintColor = .black
        contentView.addSubview(ellipsisButton)
    }
    
    private func setupConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(16)
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(50)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(16)
            make.centerY.equalTo(contentView)
            make.trailing.lessThanOrEqualTo(contentView).offset(-100)
        }
        
//        unfollowButton.snp.makeConstraints { make in
//            make.centerY.equalTo(contentView)
//            make.trailing.equalTo(ellipsisButton.snp.leading).offset(-16)
//            make.height.equalTo(30)
//            make.width.equalTo(80)
//        }
        
        ellipsisButton.snp.makeConstraints { make in
            make.trailing.equalTo(contentView).offset(-16)
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(24) 
        }
    }
}
