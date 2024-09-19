//
//  TripDetailWithPlaceTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/18.
//

import Foundation
import UIKit
import SnapKit

class TripDetailWithPlaceTableViewCell: UITableViewCell {
    
    var verseLabel = UILabel()
    var placeLabel = UILabel()
    let completeButton = UIButton(type: .system)
    let moreInfoLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: "homeCell")
        setupUI()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupUI() {
        
        self.addSubview(verseLabel)
        self.addSubview(placeLabel)
        self.addSubview(moreInfoLabel)
        self.contentView.addSubview(completeButton)
        
        verseLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(20)
            make.bottom.equalTo(self.snp.centerY).offset(-20)
        }
        
        placeLabel.snp.makeConstraints { make in
            make.leading.equalTo(verseLabel)
            make.top.equalTo(self.snp.centerY).offset(20)
        }
        
        completeButton.snp.makeConstraints { make in
            make.trailing.equalTo(self).offset(-20)
            make.centerY.equalTo(self)
        }
        
        moreInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(placeLabel.snp.bottom).offset(30)
            make.width.equalTo(self).multipliedBy(0.9)
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-15) // 確保與底部有間距
        }
        
        moreInfoLabel.numberOfLines = 0
        
        verseLabel.font = UIFont.systemFont(ofSize: 20)
        placeLabel.numberOfLines = 0
        verseLabel.numberOfLines = 0
        
        completeButton.isEnabled = true
        completeButton.tintColor = UIColor(resource: .accent)
    }
}
