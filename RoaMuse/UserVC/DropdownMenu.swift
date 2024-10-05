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
    
    // 初始化
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DropdownCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 12
        self.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - UITableViewDataSource 和 UITableViewDelegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropdownCell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = items[indexPath.row]
        onItemSelected?(selectedItem) // 傳遞選中的項目
        self.hide() // 選擇後隱藏
    }
    
    func show(in parentView: UIView, anchorView: UIView) {
        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.top.equalTo(anchorView.snp.bottom).offset(8)
            make.trailing.equalTo(anchorView)
            make.width.equalTo(150)
            make.height.equalTo(150)
        }
        
        self.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
