//
//  GradientActivityIndicatorViewViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/9.
//

import UIKit
import SnapKit

class GradientActivityIndicatorView: UIView {

    private let shapeLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let animationKey = "rotationAnimation"
    private let blurBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let backgroundView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 設定背景 view
        setupBackgroundView()
        
        // 設定圓圈 Layer
        setupCircleLayer()
        
        // 設定漸層 Layer
        setupGradientLayer()
        
        // 將 shapeLayer 作為 mask，讓漸層只顯示在圓圈上
        gradientLayer.mask = shapeLayer
    }
    
    private func setupBackgroundView() {
        // 半透明模糊背景
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        backgroundView.layer.cornerRadius = 20
        backgroundView.clipsToBounds = true
        addSubview(backgroundView)
        
        // 添加模糊效果
        backgroundView.addSubview(blurBackgroundView)
        
        // 設定背景與模糊 view 的約束
        backgroundView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(120) // 背景大小
        }
        
        blurBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // 模糊效果與背景邊界對齊
        }
    }
    
    private func setupCircleLayer() {
        // 設定圓圈 path
        let circleRadius: CGFloat = 40
        let circleCenter = CGPoint(x: 60, y: 60) // 背景 view 的中心
        let circlePath = UIBezierPath(arcCenter: circleCenter, radius: circleRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        shapeLayer.path = circlePath.cgPath
        shapeLayer.lineWidth = 6
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.strokeEnd = 0.75
    }
    
    private func setupGradientLayer() {
        gradientLayer.colors = [
            UIColor.deepBlue.cgColor,
            UIColor.deepBlue.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        backgroundView.layer.addSublayer(gradientLayer)
        
        // 設定 gradientLayer 的大小
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
    }
    
    func startAnimating() {
        if gradientLayer.animation(forKey: animationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.toValue = NSNumber(value: 2 * Double.pi)
            rotationAnimation.duration = 1.5
            rotationAnimation.repeatCount = .infinity
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // 平滑的動畫效果
            gradientLayer.add(rotationAnimation, forKey: animationKey)
        }
    }
    
    func stopAnimating() {
        if gradientLayer.animation(forKey: animationKey) != nil {
            gradientLayer.removeAnimation(forKey: animationKey)
        }
    }
}
