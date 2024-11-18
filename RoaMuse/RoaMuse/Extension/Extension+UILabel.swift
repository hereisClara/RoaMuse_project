//
//  Extension+UILabel.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/6.
//

import Foundation
import UIKit

extension UILabel {
    
    var lineSpacing: CGFloat {
        get {
            guard let attributedText = attributedText, attributedText.length > 0 else { return 0 }
            
            let paragraphStyle = attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            return paragraphStyle?.lineSpacing ?? 0
        }
        
        set {
            guard let currentText = text else { return }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = newValue
            
            let attributedString = NSMutableAttributedString(string: currentText)
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
            
            self.attributedText = attributedString
        }
    }
}
