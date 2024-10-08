//
//  StyleTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/18.
//

import Foundation
import UIKit
import SnapKit

class StyleTableViewCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let containerView = UIView() // 新增一個 containerView 來控制內縮和圓角
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        // 設置背景顏色
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        // 配置 containerView 用來內縮和設置圓角
        containerView.backgroundColor = UIColor.white
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        contentView.addSubview(containerView)
        
        // 設置 containerView 的內縮約束
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalTo(contentView).inset(8) // 四周內縮 10 點
            make.width.equalTo(contentView)
            make.centerX.equalTo(contentView)
        }
        
        // 添加 titleLabel 和 descriptionLabel 到 containerView
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        
        // 設置標題和描述標籤的佈局
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(20)
            make.top.equalTo(containerView).offset(30)
            make.trailing.equalTo(containerView).offset(-20) // 增加右側約束
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(20) // 改小一點間距
            make.trailing.equalTo(containerView).offset(-20) // 增加右側約束
            make.bottom.equalTo(containerView).offset(-20) // 確保與單元格底部有距離
        }
        
        // 調整字體
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 22)
        titleLabel.textColor = .deepBlue // 設置標題顏色
        
        descriptionLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        descriptionLabel.textColor = UIColor.systemGray
        descriptionLabel.numberOfLines = 0 // 設置自適應行數
    }
}
