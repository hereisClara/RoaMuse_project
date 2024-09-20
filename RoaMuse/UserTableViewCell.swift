//
//  UserTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/19.
//

import Foundation
import UIKit
import SnapKit

class UserTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 設置 cell 內的內容
    func setupCell() {
        let cellLabel = UILabel()
//        cellLabel.text = "User Detail"
        cellLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        
        contentView.addSubview(cellLabel)
        
        // 使用 SnapKit 進行佈局
        cellLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(16)
        }
    }
}
