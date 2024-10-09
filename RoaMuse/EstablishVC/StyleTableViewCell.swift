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
        
        containerView.backgroundColor = UIColor.white
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        containerView.layer.borderColor = UIColor.deepBlue.withAlphaComponent(0.7).cgColor
        containerView.layer.borderWidth = 2
        contentView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView).inset(8) // 四周內縮 10 點
            make.width.equalTo(contentView)
            make.centerX.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(16)
            make.top.equalTo(containerView).offset(15)
            make.trailing.equalTo(containerView).offset(-16) // 增加右側約束
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8) // 改小一點間距
            make.trailing.equalTo(containerView).offset(-16) // 增加右側約束
            make.bottom.equalTo(containerView).offset(-16) // 確保與單元格底部有距離
        }
        
        // 調整字體
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        titleLabel.textColor = .deepBlue // 設置標題顏色
        
        descriptionLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        descriptionLabel.textColor = UIColor.systemGray
        descriptionLabel.numberOfLines = 0 // 設置自適應行數
    }
}
