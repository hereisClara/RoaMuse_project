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
    var images: [UIImage] = []
    var collectionViewHeightConstraint: Constraint?
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
        layout.scrollDirection = .vertical 
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 6
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 60) / 3, height: 100)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
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
        let totalHeight = numberOfRows * 100.0 + (numberOfRows - 1) * 6.0
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
        
        if let gestureRecognizers = cell?.imageView.gestureRecognizers {
            for gesture in gestureRecognizers {
                cell?.imageView.removeGestureRecognizer(gesture)
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        cell?.imageView.isUserInteractionEnabled = true
        cell?.imageView.addGestureRecognizer(tapGesture)
        
        cell?.imageView.tag = indexPath.item
        return cell ?? UICollectionViewCell()
    }
    
    @objc func handleImageTap(_ sender: UITapGestureRecognizer) {
        
        guard let tappedImageView = sender.view as? UIImageView else {
            print("手势识别器没有附加到 UIImageView")
            return
        }

        guard let parentVC = parentViewController else {
            print("parentViewController is nil")
            return
        }

        let index = tappedImageView.tag
        
        let fullScreenVC = FullScreenImageViewController()
        fullScreenVC.images = images
        fullScreenVC.startingIndex = index
        
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
        imageView.layer.cornerRadius = 10
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
