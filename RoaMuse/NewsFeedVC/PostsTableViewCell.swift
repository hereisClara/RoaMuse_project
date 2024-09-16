//
//  PostsTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/16.
//

import Foundation
import UIKit
import FirebaseFirestore

class PostsTableViewCell: UITableViewCell {
    
    var titleLabel = UILabel()
    var authorLabel = UILabel()
    var timeLabel = UILabel()
    var contentLabel = UILabel()
    let collectButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: "homeCell")
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func setupUI() {
        
        self.addSubview(titleLabel)
        self.addSubview(authorLabel)
        self.addSubview(timeLabel)
        self.addSubview(contentLabel)
        self.contentView.addSubview(collectButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(20)
            make.bottom.equalTo(self.snp.centerY).offset(-20)
        }
        
        collectButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(self.snp.centerY).offset(20)
            make.width.height.equalTo(45)
        }
        
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        contentLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        
        collectButton.isEnabled = true
        let heartImage = UIImage(named: "heart")
        let heartFillImage = UIImage(named: "heart.fill")
        
        collectButton.setImage(heartImage, for: .normal)
        collectButton.setImage(heartFillImage, for: .selected)
        
        collectButton.tintColor = UIColor(resource: .accent)
        
    }
    
    @objc func didTapCollectButton() {
        
        collectButton.isSelected.toggle()
        
        }
        
        //        updateUserCollections(userId: "qluFSSg8P1fGmWfXjOx6")
    }

//  儲存文章收藏
    func updateUserCollections(userId: String) {
        // 獲取 Firestore 的引用
        let db = Firestore.firestore()
        
        // 指定用戶文檔的路徑
        let userRef = db.collection("user").document(userId)
        
        // 使用 `updateData` 方法只更新 followersCount 字段
        userRef.updateData([
            "bookmarkPost": [""]
        ]) { error in
            if let error = error {
                print("更新收藏數量失敗：\(error.localizedDescription)")
            } else {
                print("收藏數量更新成功！")
            }
        
    }
    
}
