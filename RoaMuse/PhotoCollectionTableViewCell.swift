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
    weak var parentViewController: UIViewController?
    
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
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 40) / 3, height: 100)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        contentView.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            self.collectionViewHeightConstraint = make.height.equalTo(0).constraint
        }
    }
    
    
    func updateImages(_ images: [UIImage]) {
        self.images = images
        collectionView.reloadData()
        
        let numberOfRows = ceil(Double(images.count) / 3.0) 
        let totalHeight = numberOfRows * 100.0 + (numberOfRows - 1) * 10.0
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        cell?.imageView.isUserInteractionEnabled = true
        cell?.imageView.addGestureRecognizer(tapGesture)
        return cell ?? UICollectionViewCell()
    }
    
    @objc func handleImageTap(_ sender: UITapGestureRecognizer) {
            guard let tappedImageView = sender.view as? UIImageView,
                  let parentVC = parentViewController else { return }

            guard let tappedCell = sender.view?.superview?.superview as? UICollectionViewCell,
                  let indexPath = collectionView.indexPath(for: tappedCell) else { return }
            
            let fullScreenVC = FullScreenImageViewController()
            fullScreenVC.images = images
            fullScreenVC.startingIndex = indexPath.item
            
            parentVC.navigationController?.pushViewController(fullScreenVC, animated: true)
        }
}

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
