//
//  MapTripTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/6.
//

import Foundation
import UIKit
import SnapKit

class MapTripTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let poemLineLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: "TripIdCell")
        setupUI()
        setupRoundedCorners()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 12
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0))
    }
    
    func setupUI() {
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(poemLineLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(16)
            make.bottom.equalTo(contentView.snp.centerY).offset(-4)
        }
        
        poemLineLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(18)
            make.top.equalTo(contentView.snp.centerY).offset(4)
        }
        
        titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 20)
        titleLabel.textColor = .deepBlue
        poemLineLabel.font = UIFont(name: "NotoSerifHK-SemiBold", size: 16)
        poemLineLabel.textColor = .systemGray2
    }
    
    func setupRoundedCorners() {
        
        contentView.layer.cornerRadius = 25
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .white
    }
}
