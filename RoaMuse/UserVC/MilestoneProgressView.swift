//
//  MilestoneProgressView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/29.
//

import Foundation
import UIKit

class MilestoneProgressView: UIView {

    // 定義里程碑的位置 (0.0 - 1.0 範圍內)
    var milestones: [Float] = [] {
        didSet {
            setNeedsDisplay() // 當里程碑數據更新時，重新繪製
        }
    }
    
    // 當前進度
    var progress: Float = 0 {
        didSet {
            setNeedsDisplay() // 當進度更新時，重新繪製
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let progressHeight: CGFloat = 10
        let progressY = (rect.height - progressHeight) / 2
        let cornerRadius = progressHeight / 2 // 圓角半徑等於進度條高度的一半
        
        // 繪製圓角背景
        let backgroundPath = UIBezierPath(roundedRect: CGRect(x: 0, y: progressY, width: rect.width, height: progressHeight), cornerRadius: cornerRadius)
        context.setFillColor(UIColor.systemGray5.cgColor)
        context.addPath(backgroundPath.cgPath)
        context.fillPath()
        
        // 繪製圓角進度條
        let progressWidth = rect.width * CGFloat(progress)
        let progressPath = UIBezierPath(roundedRect: CGRect(x: 0, y: progressY, width: progressWidth, height: progressHeight), cornerRadius: cornerRadius)
        context.setFillColor(UIColor.deepBlue.cgColor) // 根據需要調整進度條的顏色
        context.addPath(progressPath.cgPath)
        context.fillPath()
        
        // 繪製里程碑標記
        for milestone in milestones {
            let milestoneX = CGFloat(milestone) * (rect.width - 16) 
            let milestoneY = rect.midY
            let circleRect = CGRect(x: milestoneX, y: milestoneY - 8, width: 16, height: 16)
            
            // 根據進度改變里程碑的顏色
            let milestoneColor: UIColor = (milestone <= progress) ? UIColor.accent : UIColor.systemGray3
            context.setFillColor(milestoneColor.cgColor)
            context.fillEllipse(in: circleRect)
        }
    }
    
}
