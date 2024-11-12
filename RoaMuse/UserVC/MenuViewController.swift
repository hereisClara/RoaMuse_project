//
//  MenuViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/14.
//

import Foundation
import UIKit
import SnapKit
import SideMenu

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    let styles = ["奇險派", "浪漫派", "田園派"]
    var selectedIndex: IndexPath?
    let confirmButton = UIButton(type: .system)
    var onSelectionConfirmed: ((Int?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .deepBlue
        
        setupTableView()
        setupConfirmButton()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "styleCell")
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
    
    func setupConfirmButton() {
        view.addSubview(confirmButton)

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let iconImage = UIImage(named: "right-arrow")

        confirmButton.setImage(iconImage, for: .normal)
        confirmButton.tintColor = .systemGray6
        confirmButton.backgroundColor = .clear
        confirmButton.addTarget(self, action: #selector(confirmSelection), for: .touchUpInside)

        confirmButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(180)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.height.equalTo(20)
            make.width.equalTo(40)
        }
    }
    
    @objc func confirmSelection() {
        if let index = selectedIndex {
            self.onSelectionConfirmed?(index.row)
        } else {
            self.onSelectionConfirmed?(nil)
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
        cell.textLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 20)
        cell.textLabel?.textColor = .forBronze
        
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        if indexPath == selectedIndex {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .accent
        } else {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .forBronze
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == selectedIndex {
            // 如果再次選擇相同的 row，則取消選取並清空 selectedIndex
            let selectedCell = tableView.cellForRow(at: indexPath)
            selectedCell?.accessoryType = .none
            selectedCell?.textLabel?.textColor = .forBronze
            selectedIndex = nil
        } else {
            // 取消先前選中的項目
            if let previousIndex = selectedIndex {
                let previousCell = tableView.cellForRow(at: previousIndex)
                previousCell?.accessoryType = .none
                previousCell?.textLabel?.textColor = .forBronze
            }
            
            selectedIndex = indexPath
            let selectedCell = tableView.cellForRow(at: indexPath)
            selectedCell?.accessoryType = .checkmark
            selectedCell?.textLabel?.textColor = .accent
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let headerLabel = UILabel()
        headerLabel.text = "風格"
        headerLabel.font = UIFont(name: "NotoSerifHK-Black", size: 24)
        headerLabel.textColor = .white
        
        headerView.addSubview(headerLabel)
        
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(12)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 85
    }
}
