//
//  CircularProgressBar.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/5.
//

import Foundation
import UIKit

class CircularProgressBar: UIView {

    var progressLayer = CAShapeLayer()
    var trackLayer = CAShapeLayer()
    var percentageLabel = UILabel()
    var avatarImageView = UIImageView()

    var progressColor = UIColor.accent
    var trackColor = UIColor.systemGray5

    var progress: Float = 0.0 {
        didSet {
            setProgress()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        createCircularPath()
        setupAvatarImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createCircularPath()
        setupAvatarImageView()
    }

    func createCircularPath() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0), radius: bounds.width / 2.0 - 10, startAngle: -.pi / 2, endAngle: 1.5 * .pi, clockwise: true)

        trackLayer.path = circlePath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = 10.0
        trackLayer.strokeEnd = 1.0
        layer.addSublayer(trackLayer)

        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 10.0
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
    }

    func setupAvatarImageView() {
        // 設置 avatarImageView，確保它是圓形的
        let avatarSize = bounds.width * 0.7
        avatarImageView.frame = CGRect(x: (bounds.width - avatarSize) / 2, y: (bounds.height - avatarSize) / 2, width: avatarSize, height: avatarSize)
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.borderWidth = 1.0
        avatarImageView.layer.borderColor = UIColor.white.cgColor // 邊框顏色可調整
        
        avatarImageView.image = UIImage(named: "user-placeholder") // 替換為默認圖片
        
        addSubview(avatarImageView)
    }

    func setProgress() {
        progressLayer.strokeEnd = CGFloat(progress)
        percentageLabel.text = "\(Int(progress * 100))%"
    }
    
    func setAvatarImage(from url: URL) {
        // 使用 URLSession 加載圖片
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                print("Failed to load image from URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // 在主線程中更新圖片
            DispatchQueue.main.async {
                if let image = UIImage(data: data) {
                    self.avatarImageView.image = image
                }
            }
        }
        task.resume()
    }
}
