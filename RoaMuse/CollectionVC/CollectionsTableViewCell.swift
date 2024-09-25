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
    let collectButton = UIButton(type: .system)
    
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
//        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 15 // 圓角半徑
        containerView.layer.masksToBounds = false
//        contentView.layer.borderWidth = 1
//        contentView.layer.borderColor = UIColor.black.cgColor
//        containerView.layer.borderWidth = 1
//        containerView.layer.borderColor = UIColor.red.cgColor
        
        // 設置 containerView 的約束
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.bottom.equalTo(contentView).inset(10)
            make.width.equalTo(contentView)
            make.center.equalTo(contentView)
            // 讓 containerView 與 contentView 之間有 10 點的間距
        }
        
        // 添加 titleLabel 到 containerView 中
        containerView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .deepBlue
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(20)
            make.centerY.equalTo(containerView).offset(-15)
        }
        
        // 添加 collectButton 到 containerView 中
        containerView.addSubview(collectButton)
        
        collectButton.snp.makeConstraints { make in
            make.trailing.equalTo(containerView).offset(-20)
            make.centerY.equalTo(containerView).offset(15)
            make.width.height.equalTo(35) // 設置按鈕大小
        }
        
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        collectButton.tintColor = UIColor(resource: .accent)
    }
}
