//
//  AwardTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/29.
//

import UIKit
import SnapKit

class AwardTableViewCell: UITableViewCell {

    // 定義一個 Label 來顯示 award 名稱
    let awardLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
//        label.numberOfLines = 1
        return label
    }()
    
    // 自定義的里程碑進度條
    let milestoneProgressView: MilestoneProgressView = {
        let progressView = MilestoneProgressView()
        progressView.backgroundColor = .clear
        return progressView
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.numberOfLines = 0
        return label
    }()

    // 自定義初始化方法
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 設置 Cell 中的視圖
    func setupViews() {
        contentView.addSubview(awardLabel)
        contentView.addSubview(milestoneProgressView)
        contentView.addSubview(descriptionLabel)
        
        // 使用 SnapKit 設置 Auto Layout
        awardLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(10)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).offset(-20)
            make.height.equalTo(40)
        }
        
        milestoneProgressView.snp.makeConstraints { make in
            make.width.equalTo(contentView).multipliedBy(0.85)
            make.centerX.equalTo(contentView)
            make.height.equalTo(30)
            make.bottom.equalTo(contentView).offset(-10)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(awardLabel.snp.bottom).offset(20)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).offset(-20)
            make.centerX.equalTo(contentView)
        }
    }
}
