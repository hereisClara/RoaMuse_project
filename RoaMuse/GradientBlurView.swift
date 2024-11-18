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
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.9).cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        blurEffectView.layer.mask = gradientLayer
        
        blurEffectView.layoutIfNeeded()
        gradientLayer.frame = blurEffectView.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = blurEffectView.layer.mask as? CAGradientLayer {
            gradientLayer.frame = blurEffectView.bounds
        }
    }
}
