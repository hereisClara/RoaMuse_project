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
    let dateLabel = UILabel()
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
        
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        avatarImageView.backgroundColor = .blue
        
        self.contentView.addSubview(moreButton)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(dateLabel)
        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(avatarImageView)
        self.contentView.addSubview(bookmarkCountLabel)
        self.contentView.addSubview(likeCountLabel)
        self.contentView.addSubview(collectButton)
        self.contentView.addSubview(likeButton) // 加入 likeButton
        self.contentView.addSubview(commentButton) // 加入 commentButton
        self.contentView.addSubview(photoStackView)
        
        self.contentView.addSubview(scrollView)
        scrollView.addSubview(photoStackView)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.leading.trailing.equalTo(contentLabel)
            make.height.equalTo(0)  // 初始高度為 0
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
            make.top.equalTo(avatarImageView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(15)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.leading.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
            make.height.lessThanOrEqualTo(120) // 例如限制为 100 点高度
        }
        
        photoStackView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.leading.equalTo(contentLabel)
            make.trailing.equalTo(contentLabel)
            self.photoStackViewHeightConstraint = make.height.equalTo(0).constraint
        }
        
        likeButton.snp.makeConstraints { make in
            make.top.equalTo(photoStackView.snp.bottom).offset(16)
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
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(contentView).offset(-16)
            make.width.height.equalTo(20)
        }
        
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = .deepBlue
        
        likeCountLabel.font = UIFont.systemFont(ofSize: 14)
        likeCountLabel.textColor = .deepBlue
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.textColor = .darkGray
        contentLabel.font = UIFont.systemFont(ofSize: 18, weight: .light)
        
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textColor = .deepBlue
        
        dateLabel.textColor = .gray
        
        
        
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        
        setupButtonStyle()
    }
    
    func setupRoundedCorners() {
        // 設置 contentView 的圓角效果
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
                    make.width.height.equalTo(150)
                }
            }

            let totalWidth = photoUrls.count * 150 + (photoUrls.count - 1) * Int(photoStackView.spacing)
            scrollView.contentSize = CGSize(width: totalWidth, height: 150)

            scrollView.snp.updateConstraints { make in
                make.height.equalTo(150)  // 有圖片時高度設置為 150
            }
        }

        if let tableView = self.superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

}
