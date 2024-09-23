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
    
    var tapCollectButton: (() -> Void)?
    var onTripSelected: ((Trip) -> Void)?
    var fromEstablishToTripDetail: Trip?
    
    
    init() {}
    
    func showPopup(on view: UIView, with trip: Trip) {
        
        fromEstablishToTripDetail = trip
        
        versesStackView.removeAllArrangedSubviews()
        placesStackView.removeAllArrangedSubviews()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        keyWindow.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(keyWindow)
        }
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        keyWindow.addSubview(popupView)
        popupView.snp.makeConstraints { make in
            make.height.equalTo(keyWindow).multipliedBy(0.7)  // 修改這裡
            make.width.equalTo(keyWindow).multipliedBy(0.85)  // 修改這裡
            make.center.equalTo(keyWindow)  // 修改這裡
        }
        
        popupView.backgroundColor = UIColor(resource: .deepBlue)
        popupView.layer.cornerRadius = 12
        
        setupConstraints()
        
        titleLabel.text = trip.poem.title
        poetryLabel.text = trip.poem.poetry
        tripStyleLabel.text = styles[trip.tag].name
        
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
        
        // 添加詩句
        for verse in trip.poem.original {
            let verseLabel = UILabel()
            verseLabel.text = verse
            verseLabel.textColor = .white
            versesStackView.addArrangedSubview(verseLabel)
        }
        
        // 从 Firebase 加载地點详情并更新 placesStackView
        let placeIds = trip.places.map { $0.id }
        FirebaseManager.shared.loadPlaces(placeIds: placeIds) { [weak self] places in
            guard let self = self else { return }
            for tripPlace in trip.places {
                if let place = places.first(where: { $0.id == tripPlace.id }) {
                    let placeLabel = UILabel()
                    placeLabel.text = place.name
                    placeLabel.textColor = .white
                    self.placesStackView.addArrangedSubview(placeLabel)
                }
            }
        }
        
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
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
        
        if let fromEstablishToTripDetail = fromEstablishToTripDetail {
            onTripSelected?(fromEstablishToTripDetail)
        }
        
        delegate?.navigateToTripDetailPage()
    }
    
    @objc func didTapCollectButton() {
        
        tapCollectButton?()
        
    }
    
}


