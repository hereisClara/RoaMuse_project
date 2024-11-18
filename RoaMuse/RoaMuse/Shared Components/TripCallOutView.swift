//
//  TripCallOutView.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/29.
//

import Foundation
import UIKit

class TripCalloutView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var tripIds: [String] = []
    var tableView: UITableView!

    var onTripSelected: ((String) -> Void)? 
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTableView() {
        tableView = UITableView(frame: self.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40
        tableView.isScrollEnabled = true
        self.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tripIds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "tripCell")
        cell.textLabel?.text = tripIds[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTripId = tripIds[indexPath.row]
        onTripSelected?(selectedTripId)
    }
}
