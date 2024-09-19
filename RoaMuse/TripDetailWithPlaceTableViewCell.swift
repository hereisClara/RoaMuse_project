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
        
        verseLabel.font = UIFont.systemFont(ofSize: 20)
        placeLabel.numberOfLines = 0
        verseLabel.numberOfLines = 0
        
        completeButton.isEnabled = true
        completeButton.setTitle("完成", for: .normal)
        completeButton.setTitle("無法點選", for: .disabled)
        completeButton.setTitle("已完成", for: .selected)
        completeButton.tintColor = UIColor(resource: .accent)
    }
}
