//
//  PopUpView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

import Foundation
import UIKit
import SnapKit

class PopUpView {
    
    // 保存彈出視窗和背景視圖
    private var popupView = UIView()
    private var backgroundView: UIView?
    
    // 單例模式 (可選)
    static let shared = PopUpView()
    
    private init() {}
    
    func showPopup(on view: UIView, with trip: Trip) {
        
        let titleLabel = UILabel()
        let poetryLabel = UILabel()
        let tripStyleLabel = UILabel()
        
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        popupView.snp.makeConstraints { make in
            make.width.height.equalTo(view).multipliedBy(0.7)
            make.center.equalTo(view)
        }
        
        popupView.backgroundColor = UIColor(resource: .deepBlue)
        popupView.layer.cornerRadius = 12
        view.addSubview(popupView)
        
//        TODO:  詩句的label跟地點的label因為數量不確定無法直接寫死，可以參考stylish顏色選擇button的for loop作法
    }
    
}
