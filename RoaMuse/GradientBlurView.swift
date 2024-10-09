//
//  GradientBlurView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/9.
//

import Foundation
import UIKit
import SnapKit

class GradientBlurView: UIView {
    
    private let blurEffectView: UIVisualEffectView
    
    override init(frame: CGRect) {
        // 1. 創建 UIVisualEffectView 以實現模糊效果
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: frame)
        
        // 設置視圖
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // 2. 添加模糊效果視圖
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 3. 創建一個漸變遮罩來控制模糊效果的範圍
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.9).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        // 4. 將 gradientLayer 添加到 blurEffectView 並設置遮罩
        blurEffectView.layer.mask = gradientLayer
        
        // 5. 在佈局完成後設置漸變遮罩的 frame
        blurEffectView.layoutIfNeeded()
        gradientLayer.frame = blurEffectView.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 確保 gradientLayer 的大小跟隨 blurEffectView 進行更新
        if let gradientLayer = blurEffectView.layer.mask as? CAGradientLayer {
            gradientLayer.frame = blurEffectView.bounds
        }
    }
}
