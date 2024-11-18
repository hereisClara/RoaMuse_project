//
//  MilestoneProgressView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/29.
//

import Foundation
import UIKit

class MilestoneProgressView: UIView {

    var milestones: [Float] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var progress: Float = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private func imageForMilestone(at index: Int, reached: Bool) -> UIImage? {
            if !reached {
                return UIImage(named: "none-medal")
            }
            
            switch index {
            case 0:
                return UIImage(named: "bronze-medal")
            case 1:
                return UIImage(named: "silver-medal")
            case 2:
                return UIImage(named: "gold-medal")
            default:
                return UIImage(named: "none-medal")
            }
        }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let progressHeight: CGFloat = 10
        let progressY = (rect.height - progressHeight) / 2
        let cornerRadius = progressHeight / 2
        let adjustedWidth = rect.width - 12
        
        let backgroundPath = UIBezierPath(roundedRect: CGRect(x: 0, y: progressY, width: adjustedWidth, height: progressHeight), cornerRadius: cornerRadius)
        context.setFillColor(UIColor.systemGray5.cgColor)
        context.addPath(backgroundPath.cgPath)
        context.fillPath()
        
        var fitProgress = Float()
        if progress != 0 {
            fitProgress = progress + 0.0126
        } else if progress == 1 || progress == 0 {
            fitProgress = progress
        }
        
        let progressWidth = min(adjustedWidth, adjustedWidth * CGFloat(fitProgress))
        let progressPath = UIBezierPath(roundedRect: CGRect(x: 0, y: progressY, width: progressWidth, height: progressHeight), cornerRadius: cornerRadius)
        context.setFillColor(UIColor.deepBlue.cgColor)
        context.addPath(progressPath.cgPath)
        context.fillPath()
        
        for (index, milestone) in milestones.enumerated() {
            let milestoneX = CGFloat(milestone) * (rect.width - 32)
            let milestoneY = rect.midY - 16
            
            let reached = milestone <= progress
            if let image = imageForMilestone(at: index, reached: reached) {
                let imageRect = CGRect(x: milestoneX, y: milestoneY, width: 32, height: 32)
                image.draw(in: imageRect)
            }
        }
    }
    
}
