//
//  UserTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/19.
//

import Foundation
import UIKit
import SnapKit
import Kingfisher
import FirebaseCore

class UserTableViewCell: UITableViewCell {
    
    let containerView = UIView()
    let collectButton = UIButton()
    let likeButton = UIButton() // 新增的 likeButton
    let commentButton = UIButton() // 新增的 commentButton
    let titleLabel = UILabel()
    let likeCountLabel = UILabel()
    let bookmarkCountLabel = UILabel()
    let contentLabel = UILabel()
    let avatarImageView = UIImageView()
    let awardLabelView = AwardLabelView(title: "初心者")
    let dateLabel = UILabel()
    let userNameLabel = UILabel()
    let moreButton = UIButton()
    var photoStackViewHeightConstraint: Constraint?
    let photoStackView = UIStackView() // 新增的 StackView 用於顯示圖片
    let scrollView = UIScrollView()
    
    var moreButtonAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        contentView.layoutMargins = UIEdgeInsets(top: 9, left: 0, bottom: 6, right: 0)
//        contentView.preservesSuperviewLayoutMargins = false
        setupCell()
        addActions()
        setupRoundedCorners()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.layer.masksToBounds = true
//        let inset: CGFloat = 12
//        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset / 2 + 3, left: 0, bottom: inset / 4, right: 0))
//        contentView.layoutIfNeeded()
    }
    
    func setupCell() {
        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.edges.equalTo(contentView).inset(UIEdgeInsets(top: 9, left: 0, bottom: 3, right: 0))
        }

        [
            moreButton, userNameLabel, awardLabelView, titleLabel, avatarImageView, contentLabel, dateLabel,
            bookmarkCountLabel, likeCountLabel, collectButton,
            likeButton, commentButton, scrollView
        ].forEach { containerView.addSubview($0) }

        
        setupLabel()
        userNameLabel.text = "UserName"
        userNameLabel.font = UIFont(name: "NotoSerifHK-Black", size: 22)
        avatarImageView.image = UIImage(named: "user-placeholder")
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .white
        
        scrollView.addSubview(photoStackView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.leading.trailing.equalTo(contentLabel)
            make.height.equalTo(0)  // 初始高度為 0
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView).offset(-10)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(15)
        }
        
        awardLabelView.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView.snp.bottom)
            make.leading.equalTo(userNameLabel)
            make.height.equalTo(25)
        }
        
        photoStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        photoStackView.axis = .horizontal
        photoStackView.spacing = 8
        photoStackView.alignment = .center
        photoStackView.distribution = .fillEqually
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(30)
            make.leading.equalTo(containerView).offset(15)
            make.width.height.equalTo(60)
        }
    
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(awardLabelView.snp.bottom).offset(16)
            make.leading.equalTo(avatarImageView)
            make.trailing.equalTo(containerView).offset(-16)
//            make.bottom.equalTo(contentLabel.snp.top).offset(-12)
        }
        
        contentLabel.numberOfLines = 0
//        contentLabel.text = "????????????????????????????????????????????????????????????????????"
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(containerView).offset(-16)
            //make.height.equalTo(30)
            //make.bottom.equalTo(photoStackView.snp.top).offset(-10)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(photoStackView.snp.bottom).offset(12)
            make.leading.equalTo(contentLabel)
//            make.bottom.equalTo(likeButton.snp.top).offset(-12)
        }
        
//        photoStackView.snp.makeConstraints { make in
//            make.top.equalTo(contentLabel.snp.bottom).offset(12)
//            make.leading.equalTo(contentLabel)
//            make.trailing.equalTo(contentLabel)
//            make.bottom.equalToSuperview().offset(-16)
//            //            self.photoStackViewHeightConstraint = make.height.equalTo(0).constraint
//        }
        
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.equalTo(avatarImageView).offset(10)
            make.width.height.equalTo(20)
            make.bottom.equalTo(containerView).offset(-16)
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
            make.top.equalTo(avatarImageView)
            make.trailing.equalTo(containerView).offset(-16)
            make.width.height.equalTo(20)
        }
        
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .deepBlue
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        setupButtonStyle()
    }
    
    func setupLabel() {
        
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        likeCountLabel.textColor = .deepBlue
        contentLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        contentLabel.text = "加載中\n加載中"
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.textColor = .darkGray
        
        contentLabel.numberOfLines = 6
        contentLabel.lineSpacing = 3
        contentLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 22)
        titleLabel.text = "加載中\n加載中"
        
        titleLabel.textColor = .deepBlue
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byWordWrapping
        dateLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 14)
        dateLabel.text = "加載中\n加載中"
        dateLabel.textColor = .gray
        
    }
    
    func setupRoundedCorners() {

        containerView.layer.cornerRadius = 15
        containerView.layer.masksToBounds = true
//        contentView.backgroundColor = .white
    }
    
    func setupButtonStyle() {
        
        likeButton.setImage(UIImage(named: "normal_heart"), for: .normal)
        likeButton.setImage(UIImage(named: "selected_heart"), for: .selected)
        
        commentButton.setImage(UIImage(named: "normal_comment"), for: .normal)
        
        collectButton.setImage(UIImage(named: "normal_bookmark"), for: .normal)
        collectButton.setImage(UIImage(named: "selected_bookmark"), for: .selected)
    }
    
    private func addActions() {
        moreButton.addTarget(self, action: #selector(didTapMoreButton), for: .touchUpInside)
    }
    
    @objc private func didTapMoreButton() {
        moreButtonAction?()
    }
    
    func configureMoreButton(action: @escaping () -> Void) {
        moreButtonAction = action
    }
    
    func configurePhotoStackView(with photoUrls: [String]) {
        photoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if photoUrls.isEmpty {
            scrollView.isHidden = true
            scrollView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        } else {
            scrollView.isHidden = false
            
            for urlString in photoUrls {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8
                
                if let url = URL(string: urlString) {
                    imageView.kf.setImage(with: url, placeholder: UIImage(named: "user-placeholder"))
                }
                
                photoStackView.addArrangedSubview(imageView)
                
                imageView.snp.makeConstraints { make in
                    make.width.equalTo(150)
                }
            }
            
            let totalWidth = photoUrls.count * 150 + (photoUrls.count - 1) * Int(photoStackView.spacing)
            scrollView.contentSize = CGSize(width: totalWidth, height: 150)
            
            scrollView.snp.updateConstraints { make in
                make.height.equalTo(150)
            }
            self.layoutIfNeeded()
        }
        
        if let tableView = self.superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates() 
        }
    }
    
    func configure(with post: [String: Any]) {
        
        let userName = String()
        
        FirebaseManager.shared.fetchUserData(userId: post["userId"] as? String ?? "") { result in
            switch result {
            case .success(let data):
                if let userName = data["userName"] as? String {
                    self.userNameLabel.text = userName
                } else {
                    
                }
            case .failure(let error):
                
                print("Error: \(error.localizedDescription)")
                
            }
        }
        
        
        if let title = post["title"] as? String {
            titleLabel.text = title
        }
        
        // 設置內容
        if let content = post["content"] as? String {
            contentLabel.text = content
        }
        
        if let photoUrls = post["photoUrls"] as? [String] {
            configurePhotoStackView(with: photoUrls)
        }
        
        if let createdAtTimestamp = post["createdAt"] as? Timestamp {
            let createdAtString = DateManager.shared.formatDate(createdAtTimestamp)
            dateLabel.text = createdAtString
        }
        
        // 設置其他數據如 likeCount, bookmarkCount 等
        if let likeCount = post["likeCount"] as? Int {
            likeCountLabel.text = "\(likeCount)"
        }
        
        if let bookmarkCount = post["bookmarkCount"] as? Int {
            bookmarkCountLabel.text = "\(bookmarkCount)"
        }
    }
}
