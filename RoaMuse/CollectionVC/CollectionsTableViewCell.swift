//
//  CollectionsTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import SnapKit

class CollectionsTableViewCell: UITableViewCell {
    
    let containerView = UIView() // 容納所有內容的父視圖
    let titleLabel = UILabel()
    let collectButton = UIButton()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        // 設置 containerView 的外觀
        contentView.addSubview(containerView)
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 25 // 圓角半徑
        containerView.layer.masksToBounds = false
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.bottom.equalTo(contentView).inset(10)
            make.width.equalTo(contentView)
            make.center.equalTo(contentView)
        }
        
        containerView.layer.borderColor = UIColor.deepBlue.withAlphaComponent(0.7).cgColor
        containerView.layer.borderWidth = 1.5
        
        containerView.addSubview(titleLabel)
        titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 18)
        titleLabel.textColor = .deepBlue
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(20)
            make.centerY.equalTo(containerView)
        }
        
        containerView.addSubview(collectButton)
        
        collectButton.snp.makeConstraints { make in
            make.trailing.equalTo(containerView).offset(-20)
            make.centerY.equalTo(containerView)
            make.width.height.equalTo(25) // 設置按鈕大小
        }
        
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor(resource: .accent)
    }
}
