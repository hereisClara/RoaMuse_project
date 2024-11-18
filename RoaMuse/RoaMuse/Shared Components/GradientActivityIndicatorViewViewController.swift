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
    private let blurBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
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
        
        setupBackgroundView()
        
        setupCircleLayer()
        
        setupGradientLayer()
        
        gradientLayer.mask = shapeLayer
    }
    
    private func setupBackgroundView() {
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        backgroundView.layer.cornerRadius = 20
        backgroundView.clipsToBounds = true
        addSubview(backgroundView)
        
        backgroundView.addSubview(blurBackgroundView)
        backgroundView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(120)
        }
        
        blurBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupCircleLayer() {
        let circleRadius: CGFloat = 40
        let circleCenter = CGPoint(x: 60, y: 60)
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
        
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
    }
    
    func startAnimating() {
        if gradientLayer.animation(forKey: animationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.toValue = NSNumber(value: 2 * Double.pi)
            rotationAnimation.duration = 1.5
            rotationAnimation.repeatCount = .infinity
            rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) 
            gradientLayer.add(rotationAnimation, forKey: animationKey)
        }
    }
    
    func stopAnimating() {
        if gradientLayer.animation(forKey: animationKey) != nil {
            gradientLayer.removeAnimation(forKey: animationKey)
        }
    }
}
