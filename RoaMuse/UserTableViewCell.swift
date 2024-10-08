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

class UserTableViewCell: UITableViewCell {
    
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
        setupCell()
        addActions()
        setupRoundedCorners()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.layer.masksToBounds = true
        let inset: CGFloat = 12
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset, left: inset / 2, bottom: inset, right: inset / 2))
    }
    
    // 設置 cell 內的內容
    func setupCell() {
        
        userNameLabel.text = "UserName"
        userNameLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 22)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        avatarImageView.image = UIImage(named: "user-placeholder")
//        awardLabelView.updateTitle("Award Title")
        
        [
            moreButton, userNameLabel, awardLabelView, titleLabel, avatarImageView, contentLabel, dateLabel,
             bookmarkCountLabel, likeCountLabel, collectButton,
            likeButton, commentButton, photoStackView, scrollView
        ].forEach { contentView.addSubview($0) }
        
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
            make.top.equalTo(userNameLabel.snp.bottom).offset(6)
            make.leading.equalTo(userNameLabel)
            make.height.equalTo(20) // 設置適當的高度
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
            make.top.equalTo(contentView).offset(30)
            make.leading.equalTo(contentView).offset(15)
            make.width.height.equalTo(50)
        }
    
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(12)
            make.leading.equalTo(avatarImageView)
            make.trailing.equalTo(contentView).offset(-16)
            make.height.equalTo(40)
        }
        contentLabel.numberOfLines = 0
        contentLabel.text = "????????????????????????????????????????????????????????????????????"
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(contentView).offset(-16)
            //make.height.equalTo(30)
            //make.bottom.equalTo(photoStackView.snp.top).offset(-10)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(photoStackView.snp.bottom).offset(12)
            make.leading.equalTo(contentLabel)
        }
        
        photoStackView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.leading.equalTo(contentLabel)
            make.trailing.equalTo(contentLabel)
            make.bottom.equalToSuperview().offset(-16)
            //            self.photoStackViewHeightConstraint = make.height.equalTo(0).constraint
        }
        
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.leading.equalTo(avatarImageView).offset(10)
            make.width.height.equalTo(20)
            make.bottom.equalTo(contentView).offset(-16)
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
            make.trailing.equalTo(contentView).offset(-16)
            make.width.height.equalTo(20)
        }
        
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .deepBlue
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        setupLabel()
        setupButtonStyle()
    }
    
    func setupLabel() {
        
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        likeCountLabel.textColor = .deepBlue
        
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.textColor = .gray
        contentLabel.font = UIFont(name: "NotoSerifHK-SemiBold", size: 18)
        contentLabel.numberOfLines = 6
        contentLabel.lineSpacing = 6
        contentLabel.lineBreakMode = .byTruncatingTail
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 20)
        titleLabel.textColor = .deepBlue
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byWordWrapping
        
        dateLabel.textColor = .gray
        dateLabel.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setupRoundedCorners() {

        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white
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
                make.height.equalTo(0)  // 沒有圖片時高度設置為 0
            }
        } else {
            scrollView.isHidden = false
            
            for urlString in photoUrls {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8
                
                if let url = URL(string: urlString) {
                    imageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
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
        }
        
        if let tableView = self.superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates() 
        }
    }
}
