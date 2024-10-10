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
    
    private var actionButtons: [UIButton] = []
    
    init(parentViewController: UIViewController, sheetHeight: CGFloat = 300) {
        self.parentViewController = parentViewController
        self.sheetHeight = sheetHeight
        self.bottomSheetView = UIView()
        self.backgroundView = UIView()
    }
    
    // 添加按鈕方法
    func addActionButton(title: String, textColor: UIColor = .black, action: @escaping () -> Void) {
        let button = createButton(title: title, textColor: textColor)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        actionButtons.append(button)  // 將按鈕添加到陣列
    }
    
    // 設置 bottom sheet
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
        
        // 使用已添加的 actionButtons 來設置 stackView
        let stackView = UIStackView(arrangedSubviews: actionButtons)
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
    
    // 創建按鈕方法
    private func createButton(title: String, textColor: UIColor = .black) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .clear
        return button
    }
    
    // 顯示 bottom sheet
    func showBottomSheet() {
        guard let parentView = parentViewController?.view else { return }
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: parentView.frame.height - self.sheetHeight, width: parentView.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 1
        }
    }
    
    // 隱藏 bottom sheet
    @objc func dismissBottomSheet() {
        guard let parentView = parentViewController?.view else { return }
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.frame = CGRect(x: 0, y: parentView.frame.height, width: parentView.frame.width, height: self.sheetHeight)
            self.backgroundView.alpha = 0
        }
    }
    
    // 檢舉按鈕操作
    @objc func didTapImpeachButton() {
        guard let parentVC = parentViewController else { return }
        
        let alertController = UIAlertController(title: "檢舉貼文", message: "你確定要檢舉這篇貼文嗎？", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: "確定", style: .destructive) { _ in
            self.dismissBottomSheet()
        }
        alertController.addAction(confirmAction)
        parentVC.present(alertController, animated: true, completion: nil)
    }
}
