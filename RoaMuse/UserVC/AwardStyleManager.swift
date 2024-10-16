//
//  AwardStyleManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit

class AwardStyleManager {
    
    static let shared = AwardStyleManager()
    // 根據稱號更新樣式
    static func updateTitleContainerStyle(forTitle title: String, item: Int, titleContainerView: UIView, titleLabel: UILabel, dropdownButton: UIButton?) {
        switch item {
        case 0:
            // 設置樣式 for item == 0
            titleContainerView.backgroundColor = UIColor.forBronze
            titleLabel.textColor = .white
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
            dropdownButton?.tintColor = .white
            
        case 1:
            // 設置樣式 for item == 1
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderColor = UIColor.deepBlue.cgColor // 編框 .deepBlue
            titleContainerView.layer.borderWidth = 2.0 // 設置邊框寬度
            titleLabel.textColor = .deepBlue
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
            dropdownButton?.tintColor = .deepBlue
            
        case 2:
            // 設置樣式 for item == 2
            titleContainerView.backgroundColor = UIColor.accent // 底色為 .accent
            titleContainerView.layer.borderWidth = 0.0 // 沒有邊框
            titleLabel.textColor = .white
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
            dropdownButton?.tintColor = .white
            
        default:
            // 如果 item 超出範圍，給予默認樣式
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderWidth = 0.0
            titleLabel.textColor = .black
            titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
        }
    }
}
