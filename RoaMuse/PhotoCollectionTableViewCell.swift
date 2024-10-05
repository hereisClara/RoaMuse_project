//
//  CollectionTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import UIKit
import SnapKit

class PhotoCollectionTableViewCell: UITableViewCell {
    
    var collectionView: UICollectionView!
    var images: [UIImage] = []  // 圖片數據源
    var collectionViewHeightConstraint: Constraint? // 保存高度约束
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical // 垂直滚动
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 40) / 3, height: 100) // 每行3个item，宽度为屏幕宽度减去间距
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false // 禁用滚动
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        contentView.addSubview(collectionView)
        
        // 使用 SnapKit 设置 collectionView 的约束
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            self.collectionViewHeightConstraint = make.height.equalTo(0).constraint // 设置初始高度约束为0
        }
    }
    
    
    func updateImages(_ images: [UIImage]) {
        self.images = images
        collectionView.reloadData()
        
        // 动态更新高度
        let numberOfRows = ceil(Double(images.count) / 3.0) // 每行3个，计算总行数
        let totalHeight = numberOfRows * 100.0 + (numberOfRows - 1) * 10.0 // 每张图片的高度为100，行间距为10
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(totalHeight)
        }
        collectionViewHeightConstraint?.update(offset: max(totalHeight, 0))
    }
}

extension PhotoCollectionTableViewCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell
        cell?.imageView.image = images[indexPath.item]
        return cell ?? UICollectionViewCell()
    }
}

// ImageCollectionViewCell 用于显示单张图片
class ImageCollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
