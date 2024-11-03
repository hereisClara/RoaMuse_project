//
//  DropdownMenuCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/15.
//

import Foundation
import UIKit

class DropdownMenuCell: UITableViewCell {
    
    let awardLabelView = AwardLabelView(title: "", backgroundColor: .clear)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupAwardLabelView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAwardLabelView()
    }
    
    private func setupAwardLabelView() {
        contentView.addSubview(awardLabelView)
        awardLabelView.titleLabel.textAlignment = .left
        awardLabelView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.equalToSuperview().inset(8)
        }
    }

    func configure(with title: String, backgroundColor: UIColor) {
        awardLabelView.updateTitle(title)
        awardLabelView.backgroundColor = backgroundColor
    }
}
