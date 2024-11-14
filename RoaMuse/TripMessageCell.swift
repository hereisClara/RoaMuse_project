//
//  TripMessageCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/11/14.
//

import Foundation
import UIKit
import SnapKit

class TripMessageCell: UITableViewCell {
    
    let messageBubble = UIView()
    let titleLabel = UILabel()
    let moreInfoButton = UIButton(type: .system)
    let avatarImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        messageBubble.layer.cornerRadius = 12
        messageBubble.clipsToBounds = true
        messageBubble.backgroundColor = .forBronze
        contentView.addSubview(messageBubble)
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        messageBubble.addSubview(titleLabel)
        
        moreInfoButton.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        moreInfoButton.tintColor = .white
        messageBubble.addSubview(moreInfoButton)
        
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        contentView.addSubview(avatarImageView)
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.bottom.equalTo(messageBubble)
            make.left.equalToSuperview().offset(16)
        }
        
        messageBubble.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.width.lessThanOrEqualTo(250)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.leading.equalTo(messageBubble).offset(10)
            make.trailing.equalTo(moreInfoButton).offset(-12)
        }
        
        moreInfoButton.snp.remakeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(messageBubble).offset(-10)
            make.bottom.equalTo(messageBubble).offset(-10)
        }
    }
    
    func configure(isFromCurrentUser: Bool) {
        
//        FirebaseManager.shared.loadTripById(trip.id) { trip in
//            guard let trip = trip else { return }
//            FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
//                self.titleLabel.text = poem.title
//            }
//        }
        
        if isFromCurrentUser {
            messageBubble.backgroundColor = .forBronze
            titleLabel.textColor = .white
            
            avatarImageView.isHidden = true
            messageBubble.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.right.equalToSuperview().offset(-16)
                make.width.lessThanOrEqualTo(250)
            }
            
            titleLabel.snp.remakeConstraints { make in
                make.top.leading.equalTo(messageBubble).offset(10)
                make.trailing.equalTo(moreInfoButton.snp.leading).offset(-12)
            }
            
            moreInfoButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.trailing.equalTo(messageBubble).offset(-10)
                make.bottom.equalTo(messageBubble).offset(-10)
            }
        } else {
            messageBubble.backgroundColor = .forBronze
            titleLabel.textColor = .white
            
            avatarImageView.isHidden = false
            avatarImageView.snp.remakeConstraints { make in
                make.width.height.equalTo(40)
                make.bottom.equalTo(messageBubble)
                make.left.equalToSuperview().offset(16)
            }
            
            messageBubble.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10)
                make.left.equalTo(avatarImageView.snp.right).offset(8)
                make.width.lessThanOrEqualTo(250)
            }
            
            titleLabel.snp.remakeConstraints { make in
                make.top.leading.equalTo(messageBubble).offset(10)
                make.trailing.equalTo(moreInfoButton).offset(-12)
            }
            
            moreInfoButton.snp.remakeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.trailing.equalTo(messageBubble).offset(-10)
                make.bottom.equalTo(messageBubble).offset(-10)
            }
        }
    }
}
