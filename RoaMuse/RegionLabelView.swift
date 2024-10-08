//
//  RegionLabelView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/8.
//

import Foundation
import UIKit

class RegionLabelView: UIView {
    
    // regionLabel 是一個標籤來顯示區域名稱
    let regionLabel = UILabel()

    // 初始化方法，接受 region 文本參數
    init(region: String?) {
        super.init(frame: .zero)
        setupView(region: region)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(region: nil)
    }

    // 設置視圖，根據 region 判斷是否顯示
    private func setupView(region: String?) {
        self.backgroundColor = .lightGray
        self.layer.cornerRadius = 6
        self.clipsToBounds = true

        // 設置 regionLabel
        regionLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 14)
        regionLabel.textColor = .white
        regionLabel.textAlignment = .center
        addSubview(regionLabel)
        
        // 使用 Auto Layout 設置約束
        regionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            regionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 6),
            regionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -6),
            regionLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        // 根據 region 決定是否隱藏視圖
        if let region = region, !region.isEmpty {
            regionLabel.text = region
            self.isHidden = false
        } else {
            self.isHidden = true
        }
    }

    // 更新區域文字
    func updateRegion(_ region: String?) {
        if let region = region, !region.isEmpty {
            regionLabel.text = region
            self.isHidden = false
        } else {
            self.isHidden = true
        }
    }
}
