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
        return label
    }()
    
    // 自定義的里程碑進度條
    let milestoneProgressView: MilestoneProgressView = {
        let progressView = MilestoneProgressView()
        progressView.backgroundColor = .clear
        return progressView
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
        
        // 使用 SnapKit 設置 Auto Layout
        awardLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(10)
            make.leading.equalTo(contentView).offset(20)
            make.trailing.equalTo(contentView).offset(-20)
        }
        
        milestoneProgressView.snp.makeConstraints { make in
            make.top.equalTo(awardLabel.snp.bottom).offset(40)
            make.width.equalTo(contentView).multipliedBy(0.85)
            make.centerX.equalTo(contentView)
            make.height.equalTo(20)  // 設置進度條高度
            make.bottom.equalTo(contentView).offset(-10)
        }
    }
}
