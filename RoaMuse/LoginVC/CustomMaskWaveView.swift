//
//  CustomMaskWaveView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/13.
//

import Foundation
import UIKit

class CustomMaskWaveView: UIView {

    private var displayLink: CADisplayLink!
    private var waveLayer = CAShapeLayer()
    private var phase: CGFloat = 0
    private let waveHeight: CGFloat = 15

    private let staticImageName = "maskImageAtLogin"
    private let maskImageName = "maskImageAtLogin"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStaticImageView()
        setupWaveLayer()
        setupImageMask()
        startWaveAnimation() 
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStaticImageView()
        setupWaveLayer()
        setupImageMask()
        startWaveAnimation()
    }

    // MARK: - 設置靜態圖片層
    private func setupStaticImageView() {
        guard let staticImage = UIImage(named: staticImageName) else {
            print("無法載入靜態圖片：\(staticImageName)")
            return
        }

        let staticImageView = UIImageView(image: staticImage)
        staticImageView.contentMode = .scaleAspectFit
        staticImageView.frame = bounds
        addSubview(staticImageView)
        sendSubviewToBack(staticImageView)  // 將靜態圖片放在底層
    }

    // MARK: - 設置波浪層
    private func setupWaveLayer() {
        waveLayer.fillColor = UIColor.deepBlue.cgColor  // 設置波浪顏色
        layer.addSublayer(waveLayer)  // 將波浪層添加到視圖
    }

    // MARK: - 設置圖片遮罩
    private func setupImageMask() {
        guard let maskImage = UIImage(named: maskImageName) else {
            print("無法載入遮罩圖片：\(maskImageName)")
            return
        }

        let maskLayer = CALayer()
        maskLayer.contents = maskImage.cgImage
        maskLayer.frame = bounds
        maskLayer.contentsGravity = .resizeAspect

        waveLayer.mask = maskLayer  // 將遮罩應用於波浪層
    }

    // MARK: - 開始波浪動畫
    private func startWaveAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
        displayLink.add(to: .main, forMode: .common)
    }

    @objc private func updateWave() {
        phase += 0.02  // 控制波浪流動速度
        waveLayer.path = createWavePath().cgPath
    }

    // MARK: - 創建波浪路徑
    private func createWavePath() -> UIBezierPath {
        let path = UIBezierPath()
        let width = bounds.width * 1.5
        let midY = bounds.height / 2  // 波浪中心的 Y 軸位置

        path.move(to: CGPoint(x: 0, y: midY))

        for xCoor in stride(from: 0, through: width, by: 1) {
            let yCoor = waveHeight * sin(0.02 * xCoor + phase) + midY
            path.addLine(to: CGPoint(x: xCoor, y: yCoor))
        }

        path.addLine(to: CGPoint(x: width, y: bounds.height))
        path.addLine(to: CGPoint(x: 0, y: bounds.height))
        path.close()

        return path
    }

    deinit {
        displayLink.invalidate()
    }
}
