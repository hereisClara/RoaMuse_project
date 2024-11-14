//
//  SharingTripViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/11/14.
//

import Foundation
import UIKit
import SnapKit

class SharingTripViewController: UIViewController {
    
    var trip = [Trip]()
    var tripsTitle = [String]()
    let tableView = UITableView()
    var selectedButtonIndex: Int?
    var onTripSelected: ((Trip) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        loadTripsData(userId: userId)
    }
    
    func setupNavigationBar() {
        self.title = "收藏的行程"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.deepBlue,
            .font: UIFont(name: "NotoSerifHK-Black", size: 20)!
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        let cancelButton = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(dismissViewController))
        cancelButton.setTitleTextAttributes([
            .foregroundColor: UIColor.forBronze,
            .font: UIFont(name: "NotoSerifHK-Black", size: 16)!
        ], for: .normal)
        
        let sendButton = UIBarButtonItem(title: "發送", style: .plain, target: self, action: #selector(sendTrip))
        sendButton.setTitleTextAttributes([
            .foregroundColor: UIColor.forBronze,
            .font: UIFont(name: "NotoSerifHK-Black", size: 16)!
        ], for: .normal)
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = sendButton
    }

    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    @objc func sendTrip() {
        print("發送行程")
        guard let selectedButtonIndex = selectedButtonIndex else { return }
        onTripSelected?(trip[selectedButtonIndex])
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TripCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    func loadTripsData(userId: String) {
        
        self.trip.removeAll()
        
        let userRef = FirebaseManager.shared.db.collection("users").document(userId)
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("No user data found.")
                return
            }
            
            let bookmarkTripIds = data["bookmarkTrip"] as? [String] ?? []
            
            let parentDispatchGroup = DispatchGroup()
            
            parentDispatchGroup.enter()
            FirebaseManager.shared.loadBookmarkedTrips(tripIds: bookmarkTripIds) { [weak self] trips in
                guard let self = self else { parentDispatchGroup.leave(); return }
                self.trip = trips
                self.tripsTitle = Array(repeating: "", count: trips.count)
                
                let dispatchGroup = DispatchGroup()
                
                for (index, trip) in trips.enumerated() {
                    dispatchGroup.enter()
                    FirebaseManager.shared.loadPoemById(trip.poemId) { poem in
                        let poemTitle = poem.title
                        self.tripsTitle[index] = poemTitle
                        PoemCollectionManager.shared.addPoemId(trip.poemId)
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    parentDispatchGroup.leave()
                }
            }
            
            parentDispatchGroup.notify(queue: .main) {
                self.tableView.reloadData()
            }
        }
    }
}

extension SharingTripViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tripsTitle.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell") ?? UITableViewCell(style: .default, reuseIdentifier: "TripCell")
        
        cell.selectionStyle = .none
        cell.textLabel?.text = tripsTitle[indexPath.row]
        cell.textLabel?.font = UIFont(name: "NotoSerifHK-Black", size: 18)
        cell.textLabel?.textColor = .deepBlue
        
        let selectionButton = UIButton()
        selectionButton.setTitleColor(.deepBlue, for: .normal)
        selectionButton.setTitleColor(.deepBlue, for: .selected)
        selectionButton.setTitle("○", for: .normal)
        selectionButton.setTitle("●", for: .selected)
        selectionButton.addTarget(self, action: #selector(selectionButtonTapped(_:)), for: .touchUpInside)
        selectionButton.tag = indexPath.row
        selectionButton.isSelected = (indexPath.row == selectedButtonIndex)
        cell.contentView.addSubview(selectionButton)
        
        selectionButton.snp.makeConstraints { make in
            make.trailing.equalTo(cell.contentView).offset(-16)
            make.centerY.equalTo(cell.contentView)
            make.width.height.equalTo(40)
        }
        
        return cell
    }
    
    @objc func selectionButtonTapped(_ sender: UIButton) {
        
        if let previousIndex = selectedButtonIndex, previousIndex == sender.tag {
            
            sender.isSelected = false
            selectedButtonIndex = nil
        } else {
            
            for row in 0..<tripsTitle.count {
                if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)),
                   let button = cell.contentView.subviews.compactMap({ $0 as? UIButton }).first {
                    button.isSelected = false
                }
            }
            
            sender.isSelected = true
            selectedButtonIndex = sender.tag
        }
    }
    
}
