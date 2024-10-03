//
//  BottomSheetManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/3.
//

import Foundation
import UIKit
import SnapKit

class BottomSheetManager {

    private var bottomSheetView: UIView
    private var backgroundView: UIView
    private let sheetHeight: CGFloat
    private weak var parentViewController: UIViewController?
    
    init(parentViewController: UIViewController, sheetHeight: CGFloat = 300) {
        self.parentViewController = parentViewController
        self.sheetHeight = sheetHeight
        self.bottomSheetView = UIView()
        self.backgroundView = UIView()
    }
    
    func setupBottomSheet() {
        guard let parentView = parentViewController?.view else { return }

        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.frame = parentView.bounds
        backgroundView.alpha = 0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        backgroundView.addGestureRecognizer(tapGesture)
        
        bottomSheetView.backgroundColor = .white
        bottomSheetView.layer.cornerRadius = 15
        bottomSheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        bottomSheetView.frame = CGRect(x: 0, y: parentView.frame.height, width: parentView.frame.width, height: sheetHeight)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(backgroundView)
            window.addSubview(bottomSheetView)
        }
        
        let saveButton = createButton(title: "隱藏貼文")
        let impeachButton = createButton(title: "檢舉貼文")
        let blockButton = createButton(title: "封鎖用戶")
        let cancelButton = createButton(title: "取消", textColor: .red)
        
        let stackView = UIStackView(arrangedSubviews: [saveButton, impeachButton, blockButton, cancelButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        bottomSheetView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(bottomSheetView.snp.top).offset(20)
            make.leading.equalTo(bottomSheetView.snp.leading).offset(20)
            make.trailing.equalTo(bottomSheetView.snp.trailing).offset(-20)
        }
    }
    
    private func createButton(title: String, textColor: UIColor = .black) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .clear
        return button
    }
    
    // 顯示彈窗
    func showBottomSheet() {
        guard let parentView = parentViewController?.view else { return }
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: parentView.frame.height - self.sheetHeight, width: parentView.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 1
        }
    }
    
    // 隱藏彈窗
    @objc func dismissBottomSheet() {
        guard let parentView = parentViewController?.view else { return }
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: parentView.frame.height, width: parentView.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 0
        }
    }
}
