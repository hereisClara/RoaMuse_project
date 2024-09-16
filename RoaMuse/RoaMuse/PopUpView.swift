//
//  PopUpView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

import Foundation
import UIKit
import SnapKit

protocol PopupViewDelegate: AnyObject {
    func navigateToTripDetailPage()
}

class PopUpView {
    
    weak var delegate: PopupViewDelegate?
    
    // 保存彈出視窗和背景視圖
    private var popupView = UIView()
    private var backgroundView = UIView()
    
    let titleLabel = UILabel()
    let poetryLabel = UILabel()
    let tripStyleLabel = UILabel()
    
    let versesStackView = UIStackView()
    let placesStackView = UIStackView()
    let collectButton = UIButton(type: .system)
    let startButton = UIButton(type: .system)
    private var placeName = [String]()
    
    var tapCollectButton: (() -> Void)?
    
    // 單例模式 (可選)
    static let shared = PopUpView()
    
    private init() {}
    
    func showPopup(on view: UIView, with trip: Trip, and places: [Place]) {
        
        let styleArray = ["奇險派", "浪漫派", "田園派"]
        versesStackView.removeAllArrangedSubviews()
        placesStackView.removeAllArrangedSubviews()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        keyWindow.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        keyWindow.addSubview(popupView)
        popupView.snp.makeConstraints { make in
            make.height.equalTo(view).multipliedBy(0.7)
            make.width.equalTo(view).multipliedBy(0.85)
            make.center.equalTo(view)
        }
        
        popupView.backgroundColor = UIColor(resource: .deepBlue)
        popupView.layer.cornerRadius = 12
        
        setupConstraints()
        
        titleLabel.text = trip.poem.title
        poetryLabel.text = trip.poem.poetry
        tripStyleLabel.text = styleArray[trip.tag]
        
        titleLabel.textColor = .white
        poetryLabel.textColor = .white
        tripStyleLabel.textColor = .white
        
        backgroundView.alpha = 0
        popupView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = 1
            self.popupView.alpha = 1
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        backgroundView.addGestureRecognizer(tapGesture)
        
//        TODO:  詩句的label跟地點的label因為數量不確定無法直接寫死，可以參考stylish顏色選擇button的for loop作法
        
        for verse in trip.poem.original {
            
            let verseLabel = UILabel()
            verseLabel.text = verse
            verseLabel.textColor = .white
            versesStackView.addArrangedSubview(verseLabel)
            
        }
        
        for tripPlace in trip.places {
            
            for place in places {
                
                if place.id == tripPlace {
                    
                    let placeLabel = UILabel()
                    placeLabel.text = place.name
                    placeLabel.textColor = .white
                    placesStackView.addArrangedSubview(placeLabel)
                    
                }
                
            }
            
        }
        
        collectButton.setImage(UIImage(systemName: "heart"), for: .normal)
        collectButton.tintColor = .white
        collectButton.addTarget(self, action: #selector(didTapCollectButton), for: .touchUpInside)
        
        startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        startButton.tintColor = .white
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
    }
    
    func setupConstraints() {
        
        popupView.addSubview(titleLabel)
        popupView.addSubview(poetryLabel)
        popupView.addSubview(tripStyleLabel)
        popupView.addSubview(versesStackView)
        popupView.addSubview(placesStackView)
        popupView.addSubview(collectButton)
        popupView.addSubview(startButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(popupView).offset(60)
            make.centerX.equalTo(popupView)
        }
        
        poetryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalTo(popupView)
        }
        
        tripStyleLabel.snp.makeConstraints { make in
            make.top.equalTo(poetryLabel.snp.bottom).offset(10)
            make.centerX.equalTo(popupView)
        }
        
        versesStackView.snp.makeConstraints { make in
            make.top.equalTo(tripStyleLabel.snp.bottom).offset(30)
            make.centerX.equalTo(popupView)
        }
        
        versesStackView.axis = .vertical
        versesStackView.spacing = 10
        versesStackView.alignment = .center
        
        placesStackView.snp.makeConstraints { make in
            make.top.equalTo(versesStackView.snp.bottom).offset(30)
            make.centerX.equalTo(popupView)
        }
        
        placesStackView.axis = .vertical
        placesStackView.spacing = 10
        placesStackView.alignment = .center
        
        collectButton.snp.makeConstraints { make in
            make.bottom.equalTo(popupView).offset(-50)
            make.centerX.equalTo(popupView).offset(40)
            make.width.height.equalTo(30)
        }
        
        startButton.snp.makeConstraints { make in
            make.bottom.equalTo(popupView).offset(-50)
            make.centerX.equalTo(popupView).offset(-40)
            make.width.height.equalTo(30)
        }
        
    }
    
    @objc func dismissPopup() {
        print("hi")
     
        // 動畫隱藏 popupView 和 backgroundView
        UIView.animate(withDuration: 0.3, animations: {
            self.popupView.alpha = 0
            self.backgroundView.alpha = 0
        }) { _ in
            // 完成動畫後移除 popupView 和 backgroundView
            self.popupView.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
            
        }
    }
    
    @objc func didTapStartButton() {
        
        popupView.removeFromSuperview()
        self.backgroundView.removeFromSuperview()
        delegate?.navigateToTripDetailPage()
    }
    
    @objc func didTapCollectButton() {
        
        tapCollectButton?()
        
    }
    
    
    
}
