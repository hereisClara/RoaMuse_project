//
//  DropdownMenu.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/1.
//

import Foundation
import UIKit

class DropdownMenu: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var items: [String] = []
    private let tableView = UITableView()
    var onItemSelected: ((String) -> Void)?
    var titlesWithIndexes: [(title: String, section: Int, row: Int)] = []
    
    init(items: [String]) {
        super.init(frame: .zero)
        self.items = items
        setupTableView()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.backgroundColor = .white
        self.layer.cornerRadius = 8
    }
    
    private func setupTableView() {
        tableView.register(DropdownMenuCell.self, forCellReuseIdentifier: "DropdownMenuCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 12
        tableView.separatorStyle = .none
        self.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - UITableViewDataSource 和 UITableViewDelegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        45
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DropdownMenuCell", for: indexPath) as? DropdownMenuCell else {
            return UITableViewCell()
        }
        
        let title = items[indexPath.row]
        let index = titlesWithIndexes[indexPath.row]
        print(items)
        print(titlesWithIndexes)
        
        cell.selectionStyle = .none
        cell.awardLabelView.titleLabel.text = index.title
        
        AwardStyleManager.updateTitleContainerStyle(
            forTitle: title,
            item: index.row,
            titleContainerView: cell.awardLabelView,
            titleLabel: cell.awardLabelView.titleLabel,
            dropdownButton: nil
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = items[indexPath.row]
//        onItemSelected?(selectedItem) // 傳遞選中的項目
        self.hide { [weak self] in
                self?.onItemSelected?(selectedItem) // 傳遞選中的項目
            }
    }
    
    func show(in parentView: UIView, anchorView: UIView) {
        parentView.addSubview(self)
        
        self.snp.makeConstraints { make in
            make.top.equalTo(anchorView.snp.bottom).offset(6)
            make.leading.equalTo(anchorView)
            make.width.equalTo(174)
            make.height.equalTo(200)
        }
        
        self.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()  // 在隱藏動畫完成後執行 completion block
        }
    }
}
