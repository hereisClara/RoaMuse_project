//
//  AwardLabelView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/1.
//

import Foundation
import UIKit

class AwardLabelView: UIView {
    
    // 定義一個 UILabel
    private let titleLabel = UILabel()
    
    // 點擊手勢的回調
    var onTap: (() -> Void)?
    
    // 初始化方法
    init(title: String, backgroundColor: UIColor = .lightGray) {
        super.init(frame: .zero)
        
        // 設置背景顏色
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        // 配置 titleLabel
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        
        // 將 titleLabel 加入到視圖中
        addSubview(titleLabel)
        
        // 設置 titleLabel 的 Auto Layout
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10) // 標籤與邊框之間留一些間隙
            make.centerY.equalToSuperview()
        }
        
        // 添加點擊手勢
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 點擊手勢處理方法
    @objc private func handleTap() {
        onTap?()  // 呼叫回調
    }
    
    // 更新標題文字
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
}
