//
//  MenuViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/14.
//

import Foundation
import UIKit
import SnapKit

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    let styles = ["奇險派", "浪漫派", "田園派"]
    var selectedIndex: IndexPath?
    let confirmButton = UIButton(type: .system)
    var onSelectionConfirmed: ((Int) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupTableView()
        setupConfirmButton()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "styleCell")
        tableView.tableFooterView = UIView()
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setupConfirmButton() {
            view.addSubview(confirmButton)
            
            confirmButton.setTitle("確定", for: .normal)
            confirmButton.backgroundColor = .systemBlue
            confirmButton.setTitleColor(.white, for: .normal)
            confirmButton.layer.cornerRadius = 10
            confirmButton.addTarget(self, action: #selector(confirmSelection), for: .touchUpInside)

            // 使用 SnapKit 設置按鈕的約束
            confirmButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
                make.height.equalTo(50)
            }
    }
    
    @objc func confirmSelection() {
        print("確定")
        guard let index = selectedIndex else {
            print("尚未選擇風格")
            return
        }
        
//        delegate?.didSelectStyle(index: index.row)
        
//        let mapVC = MapViewController()
//        mapVC.loadCompletedPlacesAndAddAnnotations(selectedIndex: Int(index.row))
        
        self.dismiss(animated: true) {
                self.onSelectionConfirmed?(index.row)
            }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "styleCell", for: indexPath)
        cell.textLabel?.text = styles[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        cell.textLabel?.textColor = .darkGray
        
        if indexPath == selectedIndex {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .systemBlue
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .darkGray
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 取消先前選中的項目
        if let previousIndex = selectedIndex {
            let previousCell = tableView.cellForRow(at: previousIndex)
            previousCell?.accessoryType = .none
            previousCell?.textLabel?.textColor = .darkGray
        }
        
        // 設定新的選中項目
        selectedIndex = indexPath
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.accessoryType = .checkmark
        selectedCell?.textLabel?.textColor = .systemBlue
        
        tableView.deselectRow(at: indexPath, animated: true)  // 取消點擊高亮效果
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .lightGray
        
        let headerLabel = UILabel()
        headerLabel.text = "風格"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20)
        headerLabel.textColor = .black
        
        headerView.addSubview(headerLabel)
        
        // 使用 SnapKit 設置 Header Label 的位置
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 70  // 設置 Header 高度
    }
}
