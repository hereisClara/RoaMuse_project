//
//  ImageViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/6.
//

import Foundation
import UIKit
import SnapKit

class ImageViewController: UIViewController {
    
    var image: UIImage?
    var index: Int = 0
    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupImageView()
    }
    
    func setupImageView() {
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
