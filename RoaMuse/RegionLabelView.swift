//
//  RegionLabelView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/8.
//

import Foundation
import UIKit

class RegionLabelView: UIView {
    
    let regionLabel = UILabel()

    init(region: String?) {
        super.init(frame: .zero)
        setupView(region: region)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(region: nil)
    }

    private func setupView(region: String?) {
        self.backgroundColor = .lightGray
        self.layer.cornerRadius = 6
        self.clipsToBounds = true

        regionLabel.font = UIFont(name: "NotoSerifHK-Black", size: 14)
        regionLabel.textColor = .white
        regionLabel.textAlignment = .center
        addSubview(regionLabel)
        
        regionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            regionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            regionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            regionLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        if let region = region, !region.isEmpty {
            regionLabel.text = region
            self.isHidden = false
        } else {
            self.isHidden = true
        }
    }

    func updateRegion(_ region: String?) {
        if let region = region, !region.isEmpty {
            regionLabel.text = region
            self.isHidden = false
        } else {
            self.isHidden = true
        }
    }
}
