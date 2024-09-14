//
//  Extension+UIStackView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/14.
//

import Foundation
import UIKit
extension UIStackView {
    
    // 移除所有 arrangedSubviews
    func removeAllArrangedSubviews() {
        // 從 stackView 中移除 arrangedSubviews
        let arrangedSubviews = self.arrangedSubviews
        
        for view in arrangedSubviews {
            self.removeArrangedSubview(view)
            view.removeFromSuperview()  // 從視圖層次結構中移除
        }
    }
}
