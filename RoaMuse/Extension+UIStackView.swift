//
//  Extension+UIStackView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/14.
//

import Foundation
import UIKit
extension UIStackView {
    
    func removeAllArrangedSubviews() {
        let arrangedSubviews = self.arrangedSubviews
        
        for view in arrangedSubviews {
            self.removeArrangedSubview(view)
            view.removeFromSuperview() 
        }
    }
}
