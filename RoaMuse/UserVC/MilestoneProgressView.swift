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
    
    private func imageForMilestone(at index: Int, reached: Bool) -> UIImage? {
            if !reached {
                return UIImage(named: "none-medal") // 未達成的里程碑
            }
            
            switch index {
            case 0:
                return UIImage(named: "bronze-medal") // 第一個里程碑 -> 銅獎
            case 1:
                return UIImage(named: "silver-medal") // 第二個里程碑 -> 銀獎
            case 2:
                return UIImage(named: "gold-medal") // 最後一個里程碑 -> 金獎
            default:
                return UIImage(named: "none-medal") // 預設情況下
            }
        }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let progressHeight: CGFloat = 10
        let progressY = (rect.height - progressHeight) / 2
        let cornerRadius = progressHeight / 2 // 圓角半徑等於進度條高度的一半
        let adjustedWidth = rect.width - 12
        // 繪製圓角背景
        let backgroundPath = UIBezierPath(roundedRect: CGRect(x: 0, y: progressY, width: adjustedWidth , height: progressHeight), cornerRadius: cornerRadius)
        context.setFillColor(UIColor.systemGray5.cgColor)
        context.addPath(backgroundPath.cgPath)
        context.fillPath()
        
        var fitProgress = Float()
        if progress != 0 {
            fitProgress = progress + 0.0125
        } else if progress == 1 || progress == 0 {
            fitProgress = progress
        }
        
        // 繪製圓角進度條
        let progressWidth = min(adjustedWidth, adjustedWidth * CGFloat(fitProgress))
        let progressPath = UIBezierPath(roundedRect: CGRect(x: 0, y: progressY, width: progressWidth, height: progressHeight), cornerRadius: cornerRadius)
        context.setFillColor(UIColor.deepBlue.cgColor) // 根據需要調整進度條的顏色
        context.addPath(progressPath.cgPath)
        context.fillPath()
        
        // 繪製里程碑標記
        for (index, milestone) in milestones.enumerated() {
            let milestoneX = CGFloat(milestone) * (rect.width - 32) // 假設圖標的寬度為 32px
            let milestoneY = rect.midY - 16 // 假設圖標的高度為 32px
            
            // 根據當前進度確定里程碑是否已達成
            let reached = milestone <= progress
            if let image = imageForMilestone(at: index, reached: reached) {
                // 確保圖片不會被裁切，並按原比例顯示
                let imageRect = CGRect(x: milestoneX, y: milestoneY, width: 32, height: 32)
                image.draw(in: imageRect)
            }
        }
    }
    
}
