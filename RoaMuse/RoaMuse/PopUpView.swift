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
    
    private var popupView = UIView()
    private var backgroundView = UIView()
    
    let titleLabel = UILabel()
    let poetryLabel = UILabel()
    let tripStyleLabel = UILabel()
    
    let versesStackView = UIStackView()
    let placesStackView = UIStackView()
    let collectButton = UIButton(type: .system)
    let startButton = UIButton(type: .system)
    
    var tapCollectButton: (() -> Void)?
    var onTripSelected: ((Trip) -> Void)?
    var fromEstablishToTripDetail: Trip?
    
    init() {}
    
    func showPopup(on view: UIView, with trip: Trip) {
        
        print("showPopup")

        fromEstablishToTripDetail = trip

        // 先清空之前的內容
        versesStackView.removeAllArrangedSubviews()
        placesStackView.removeAllArrangedSubviews()

        // 設置背景視圖
        backgroundView.frame = view.bounds
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5) // 設置背景的半透明效果
        view.addSubview(backgroundView)
        
        // 設置彈出視圖
        popupView.backgroundColor = UIColor.darkGray
        popupView.layer.cornerRadius = 10
        popupView.clipsToBounds = true
        view.addSubview(popupView)
        
        popupView.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.8)
            make.height.equalTo(400)
        }

        setupConstraints()

        // 使用 poemId 從 Firebase 中查找詩詞資料
        FirebaseManager.shared.loadPoemById(trip.poemId) { [weak self] poem in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.titleLabel.text = poem.title
                self.poetryLabel.text = "\(poem.poetry)"  // 顯示詩人名稱
                self.tripStyleLabel.text = "風格: \(poem.tag)"  // 假設風格用 tag 表示
                
                // 添加詩句
                for verse in poem.content {
                    let verseLabel = UILabel()
                    verseLabel.text = verse
                    verseLabel.textColor = .white
                    self.versesStackView.addArrangedSubview(verseLabel)
                }
            }
        }

        // 使用 placeIds 從 Firebase 中查找地點資料
        FirebaseManager.shared.loadPlaces(placeIds: trip.placeIds) { [weak self] places in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                for place in places {
                    let placeLabel = UILabel()
                    placeLabel.text = place.name  // 顯示地點名稱
                    placeLabel.textColor = .white
                    self.placesStackView.addArrangedSubview(placeLabel)
                }
            }
        }

        // 顯示彈出視圖動畫
        backgroundView.alpha = 0
        popupView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = 1
            self.popupView.alpha = 1
        }
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
        
        if let fromEstablishToTripDetail = fromEstablishToTripDetail {
            onTripSelected?(fromEstablishToTripDetail)
        }
        
        delegate?.navigateToTripDetailPage()
    }
    
    @objc func didTapCollectButton() {
        
        tapCollectButton?()
        
    }
    
}


