//
//  AwardTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/29.
//

import UIKit
import SnapKit

class AwardTableViewCell: UITableViewCell {
    
    let awardLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "NotoSerifHK-Black", size: 18)
        label.textColor = .deepBlue
        return label
    }()
    
    let milestoneProgressView: MilestoneProgressView = {
        let progressView = MilestoneProgressView()
        progressView.backgroundColor = .clear
        return progressView
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "NotoSerifHK-Bold", size: 16)
        label.textColor = .lightGray
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupRoundedCorners()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.addSubview(awardLabel)
        contentView.addSubview(milestoneProgressView)
        contentView.addSubview(descriptionLabel)
        
        let padding: CGFloat = 16
        
        awardLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(10)
            make.leading.equalTo(contentView).offset(padding)
            make.trailing.equalTo(contentView).offset(-padding)
            make.height.equalTo(40)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(awardLabel.snp.bottom).offset(12)
            make.leading.equalTo(contentView).offset(padding)
            make.trailing.equalTo(contentView).offset(-padding)
        }
        
        milestoneProgressView.snp.makeConstraints { make in
            make.width.equalTo(contentView).multipliedBy(0.85)
            make.centerX.equalTo(contentView)
            make.height.equalTo(30)
            make.bottom.equalTo(contentView).offset(-16)
        }
    }
    
    func setupRoundedCorners() {
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemGray6
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 12
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
    }
}
