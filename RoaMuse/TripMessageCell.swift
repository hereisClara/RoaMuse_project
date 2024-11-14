//
//  TripMessageCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/11/14.
//

import Foundation
import UIKit
import SnapKit

class TripMessageCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let moreInfoButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        contentView.backgroundColor = .deepBlue
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Black", size: 16)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)
        
        moreInfoButton.setTitle("More Info", for: .normal)
        moreInfoButton.setTitleColor(.white, for: .normal)
        contentView.addSubview(moreInfoButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
        }
        
        moreInfoButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.trailing.equalTo(contentView).offset(-16)
            make.bottom.equalTo(contentView).offset(-16)
        }
    }
    
    func configure(with trip: Trip) {
        
        FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
            self.titleLabel.text = poem.title
        }
        
        // Add target for the button if needed
        // moreInfoButton.addTarget(self, action: #selector(yourMethod), for: .touchUpInside)
    }
}
