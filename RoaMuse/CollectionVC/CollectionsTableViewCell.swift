//
//  CollectionsTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import SnapKit

class CollectionsTableViewCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let collectButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: "collectionsCell")
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupUI() {
        
        self.addSubview(titleLabel)
        self.contentView.addSubview(collectButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(20)
            make.bottom.equalTo(self.snp.centerY).offset(-20)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(self.snp.centerY).offset(20)
            make.width.height.equalTo(35)
        }
        
        collectButton.isEnabled = true
        let heartImage = UIImage(named: "heart")
        let heartFillImage = UIImage(named: "heart.fill")
        
        collectButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        collectButton.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        
        collectButton.tintColor = UIColor(resource: .accent)
        
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        
    }
    
}
