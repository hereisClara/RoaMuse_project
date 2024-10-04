//
//  CollectionTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/4.
//

import Foundation
import UIKit
import SnapKit

class CollectionTableViewCell: UITableViewCell {
    
    var collectionView: UICollectionView!
    var images: [UIImage] = []  // 圖片數據源
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal  // 水平滾動
        layout.itemSize = CGSize(width: 100, height: 100)  // 設置每個圖片單元格的大小
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView.backgroundColor = .white
        contentView.addSubview(collectionView)
        
        // 使用 SnapKit 設置約束
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
            make.height.equalTo(120)  // 固定高度
        }
    }
    
    // 更新圖片數據
    func updateImages(_ images: [UIImage]) {
        self.images = images
        collectionView.reloadData()
    }
}

extension CollectionTableViewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        
        // 每次移除之前的 subview，避免重用錯誤
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // 添加圖片
        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.image = images[indexPath.row]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        cell.contentView.addSubview(imageView)
        
        return cell
    }
}
