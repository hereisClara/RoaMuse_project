//
//  AwardLabelView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/1.
//

import Foundation
import UIKit

class AwardLabelView: UIView {
    
    let titleLabel = UILabel()
    var onTap: (() -> Void)?
    
    init(title: String, backgroundColor: UIColor = .systemGray) {
        super.init(frame: .zero)
        
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = 6
        self.clipsToBounds = true
        
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 14)
        titleLabel.textColor = .white
        
        addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    func updateTitle(_ title: String) {
        print("Updating title with: \(title)")
        titleLabel.text = title
    }
    
    func updateStyle(backgroundColor: UIColor, textColor: UIColor) {
        self.backgroundColor = backgroundColor
        titleLabel.textColor = textColor
    }
}
