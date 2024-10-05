//
//  AwardStyleManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit

class AwardStyleManager {
    // 根據稱號更新樣式
    static func updateTitleContainerStyle(forTitle title: String, titleContainerView: UIView, titleLabel: UILabel, dropdownButton: UIButton) {
        switch title {
        case "稱號1": // 進度點 1
            titleContainerView.backgroundColor = UIColor.brown // 深棕色
            titleContainerView.layer.borderColor = UIColor.lightGray.cgColor // 編框淺灰色
            titleContainerView.layer.borderWidth = 2.0 // 設置邊框寬度
            titleLabel.textColor = .white
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            dropdownButton.tintColor = .white
            
        case "稱號2": // 進度點 2
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderColor = UIColor.deepBlue.cgColor // 編框 .deepBlue
            titleContainerView.layer.borderWidth = 2.0 // 設置邊框寬度
            titleLabel.textColor = .deepBlue
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            dropdownButton.tintColor = .deepBlue
            
        case "稱號3": // 進度點 3
            titleContainerView.backgroundColor = UIColor.accent // 底色為 .accent
            titleContainerView.layer.borderWidth = 0.0 // 沒有邊框
            titleLabel.textColor = .white
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            dropdownButton.tintColor = .white
            
        default:
            titleContainerView.backgroundColor = UIColor.systemBackground
            titleContainerView.layer.borderWidth = 0.0
            titleLabel.textColor = .black
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
    }
}
