//
//  TripDetailViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/14.
//

import Foundation
import UIKit
import CoreLocation
import SnapKit
import MapKit
import FirebaseFirestore

class TripDetailViewController: UIViewController {
    
    var savedSuggestions: [String: String] = [:]
    var buttonContainer: UIStackView = UIStackView()
    var transportButtons: [UIButton] = []
    var selectedTransportButton: UIButton?
    var isExpanded: Bool = false
    var buttonsViewWidthConstraint: Constraint?
    var selectedTransportType: MKDirectionsTransportType = .automobile
    var transportBackgroundView: UIView?
    var transportButtonsViewWidthConstraint: Constraint?
    let locationButton = UIButton()
    var mapVisibilityState: [Int: Bool] = [:]
    var keywordToLineMap = [String: String]()
    var matchingPlaces = [(keyword: String, place: Place)]()
    var placePoemPairs = [PlacePoemPair]()
    
    let buttonTitles = ["car.fill", "figure.walk", "bicycle", "tram.fill"]
    
    var currentTargetIndex: Int = 0
    var loadedPoem: Poem?
    var trip: Trip?
    var onTripReceivedFromHome: ((Trip) -> Void)?
    let placesStackView = UIStackView()
    private let locationManager = LocationManager()
    private var places = [Place]()
    private var placeName = [String]()
    let distanceThreshold: Double = 20000
    private var buttonState = [Bool]()
    var selectedIndexPath: IndexPath?
    var completedPlaceIds: [String] = []
    
    var tableView = UITableView()
    
    let progressView = UIView() // The vertical progress view container
    let progressBar = UIProgressView(progressViewStyle: .bar) // The actual progress bar
    var progressDots = [UIView]()
    
    var totalTravelTime: TimeInterval? // 用來存儲總交通時間
    var routesArray: [[MKRoute]]?
    var nestedInstructions: [[String]]?
    
    var footerViews = [Int: UIView]()
    
    private var isMapVisible: Bool = false
    var isFlipped: [Int: Bool] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor.backgroundGray
        navigationController?.navigationBar.tintColor = UIColor.deepBlue
        
        navigationItem.backButtonTitle = ""
        self.buttonState = []
        getPoemPlacePair()
        if let nestedInstructions = nestedInstructions {
            for (index, steps) in nestedInstructions.enumerated() {
                print("導航段落 \(index):")
                for instruction in steps {
                    print("指令: \(instruction)")
                }
            }
        }
        self.navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(resource: .backgroundGray)
        
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareButtonTapped))
        self.navigationItem.rightBarButtonItem = shareButton
        
        if let poemId = trip?.poemId {
            FirebaseManager.shared.loadPoemById(poemId) { [weak self] poem in
                guard let self = self else { return }
                self.updatePoemData(poem: poem)
            }
        }
        
        if let trip = trip {
            fetchPlacePoemPairs(for: trip.id) { pair in
                if let pair = pair {
                    self.placePoemPairs.append(contentsOf: pair)
                    print(self.placePoemPairs)
                }
            }
        }
        setupTableView()
        loadPlacesDataFromFirebase()
        loadPoemDataFromFirebase()
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        FirebaseManager.shared.fetchCompletedPlaces(userId: userId) { [weak self] completedPlaces in
            guard let self = self else { return }
            
            self.completedPlaceIds = []
            
            for completedPlace in completedPlaces {
                if let tripId = completedPlace["tripId"] as? String,
                   let placeIds = completedPlace["placeIds"] as? [String],
                   tripId == self.trip?.id {
                    self.completedPlaceIds.append(contentsOf: placeIds)
                }
            }
            DispatchQueue.main.async {
                print(self.footerViews)
                for (index, place) in self.places.enumerated() {
                    if self.completedPlaceIds.contains(place.id), let footerView = self.footerViews[index] {
                        self.setupCompletedFooterView(footerView: footerView, sectionIndex: index)
                    }
                }
                self.tableView.reloadData()
            }
        }
        
        FirebaseManager.shared.fetchCompletedPlaces(userId: userId) { [weak self] completedPlaces in
            guard let self = self else { return }
            
            self.completedPlaceIds = []
            
            for completedPlace in completedPlaces {
                if let tripId = completedPlace["tripId"] as? String,
                   let placeIds = completedPlace["placeIds"] as? [String],
                   tripId == self.trip?.id {
                    self.completedPlaceIds.append(contentsOf: placeIds)
                }
            }
            
            DispatchQueue.main.async {
                // 遍歷所有 section 並設置已完成的地點
                for (index, place) in self.places.enumerated() {
                    if self.completedPlaceIds.contains(place.id), let footerView = self.footerViews[index] {
                        self.setupCompletedFooterView(footerView: footerView, sectionIndex: index)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func getPoemPlacePair() {
        
        placePoemPairs.removeAll()
        
        for matchingPlace in matchingPlaces {
            let keyword = matchingPlace.keyword
            
            if let poemLine = keywordToLineMap[keyword] {
                let placePoemPair = PlacePoemPair(placeId: matchingPlace.place.id, poemLine: poemLine)
                placePoemPairs.append(placePoemPair)
            }
        }
    }
    
    func updateProgress(for placeIndex: Int) {
        if placeIndex < progressDots.count {
            let dot = progressDots[placeIndex]
            dot.backgroundColor = .blue // Change color to indicate completion
        }
    }
    
    @objc func shareButtonTapped() {
        let alertController = UIAlertController(title: nil, message: "選擇操作", preferredStyle: .actionSheet)
        
        let postAction = UIAlertAction(title: "撰寫日記", style: .default) { [weak self] _ in
            let postVC = PostViewController()
            postVC.selectedTrip = self?.trip
            self?.navigationController?.pushViewController(postVC, animated: true)
        }
        
        let shareAction = UIAlertAction(title: "分享小卡", style: .default) { [weak self] _ in
            let photoVC = PhotoUploadViewController()
            photoVC.selectedTrip = self?.trip
            self?.navigationController?.pushViewController(photoVC, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(postAction)
        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func loadPoemDataFromFirebase() {
        
        self.loadedPoem = nil
        
        guard let trip = trip else { return }
        
        FirebaseManager.shared.loadPoemById(trip.poemId) { [weak self] poem in
            guard let self = self else { return }
            
            self.loadedPoem = poem
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func updatePoemData(poem: Poem) {
        self.tableView.reloadData()
    }
    
    func loadPlacesDataFromFirebase() {
        
        guard let trip = trip else { return }
        self.places = self.matchingPlaces.map { $0.place }
        self.places.sort { (place1, place2) -> Bool in
            guard let index1 = trip.placeIds.firstIndex(of: place1.id),
                  let index2 = trip.placeIds.firstIndex(of: place2.id) else {
                return false
            }
            return index1 < index2
        }
        
        let placeIds = trip.placeIds
        
        if placeIds.isEmpty {
            return
        }
        
        FirebaseManager.shared.loadPlaces(placeIds: placeIds) { [weak self] (placesArray) in
            guard let self = self else { return }
            
            self.matchingPlaces = trip.placeIds.compactMap { placeId in
                if let place = placesArray.first(where: { $0.id == placeId }) {
                    return (keyword: "未知关键字", place: place)
                } else {
                    return nil
                }
            }
            self.places = self.matchingPlaces.map { $0.place }
            
            if let lastCompletedPlaceId = self.completedPlaceIds.last,
               let lastCompletedIndex = self.places.firstIndex(where: { $0.id == lastCompletedPlaceId }) {
                self.currentTargetIndex = lastCompletedIndex + 1
            } else {
                self.currentTargetIndex = 0
            }
            self.placeName = self.places.map { $0.name }
            
            DispatchQueue.main.async {
                self.places = self.matchingPlaces.map { $0.place }
                
                self.buttonState = Array(repeating: false, count: self.places.count)
                
                self.tableView.reloadData()
                
                for (index, place) in self.places.enumerated() {
                    if self.completedPlaceIds.contains(place.id), let footerView = self.footerViews[index] {
                        self.setupCompletedFooterView(footerView: footerView, sectionIndex: index)
                    }
                }
                
                self.locationManager.startUpdatingLocation()
                self.locationManager.onLocationUpdate = { [weak self] currentLocation in
                    guard let self = self else { return }
                    self.checkDistanceForCurrentTarget(from: currentLocation)
                }
            }
            self.checkIfAllPlacesCompleted()
        }
    }
    
    func checkDistanceForCurrentTarget(from currentLocation: CLLocation) {
        guard currentTargetIndex < places.count else {
            print("所有地点都已完成")
            self.locationManager.stopUpdatingLocation()
            return
        }
        
        guard currentTargetIndex < buttonState.count else {
            return
        }
        
        let place = places[currentTargetIndex]
        let targetLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
        let distance = currentLocation.distance(from: targetLocation)
        print("距离 \(place.name): \(distance) 米")
        
        let isWithinThreshold = distance <= distanceThreshold
        
        if isWithinThreshold != buttonState[currentTargetIndex] {
            buttonState[currentTargetIndex] = isWithinThreshold
            
            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(integer: self.currentTargetIndex), with: .none)
            }
        }
    }
}

extension TripDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        
        guard let poem = loadedPoem else {
            return createLoadingHeaderView()
        }
        
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.isUserInteractionEnabled = true
        
        let headerView = createHeaderView(poem: poem)
        headerView.isUserInteractionEnabled = true
        containerView.addSubview(headerView)
        
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        let buttonsView = createButtonsView()
        containerView.addSubview(buttonsView)
        
        buttonsView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        return containerView
    }
    
    private func createLoadingHeaderView() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = .deepBlue
        let label = UILabel()
        label.text = "詩句加載中"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24)
        headerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return headerView
    }
    
    private func createHeaderView(poem: Poem) -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(resource: .deepBlue)
        headerView.layer.cornerRadius = 20
        
        let titleLabel = createLabel(text: poem.title, font: UIFont(name: "NotoSerifHK-Black", size: 24) ?? UIFont.systemFont(ofSize: 24))
        
        headerView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(12)
        }
        
        let poetLabel = createLabel(text: poem.poetry, font: UIFont(name: "NotoSerifHK-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20))
        headerView.addSubview(poetLabel)
        
        poetLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
        }
        
        let contentLabel = createLabel(text: poem.content.joined(separator: "\n"), font: UIFont(name: "NotoSerifHK-Black", size: 20) ?? UIFont.systemFont(ofSize: 20))
        contentLabel.numberOfLines = 0
        headerView.addSubview(contentLabel)
        contentLabel.textAlignment = .left
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(poetLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        return headerView
    }
    
    private func createLabel(text: String, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.textAlignment = .center
        label.font = font
        return label
    }
    
    private func createButtonsView() -> UIView {
        let buttonsView = UIView()
        buttonsView.isUserInteractionEnabled = true
        
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = .white
        locationButton.isSelected = false
        locationButton.backgroundColor = .systemGray4
        locationButton.layer.cornerRadius = 25
        locationButton.addTarget(self, action: #selector(didTapLocateButton(_:)), for: .touchUpInside)
        locationButton.isUserInteractionEnabled = true
        
        buttonsView.addSubview(locationButton)
        
        locationButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
        
        let transportButtonsView = UIView()
        transportButtonsView.isUserInteractionEnabled = true
        buttonsView.addSubview(transportButtonsView)
        
        transportButtonsView.snp.makeConstraints { make in
            make.leading.equalTo(locationButton.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            transportButtonsViewWidthConstraint = make.width.equalTo(50).constraint
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemGray4
        backgroundView.layer.cornerRadius = 25
        backgroundView.isHidden = true
        transportButtonsView.addSubview(backgroundView)
        transportButtonsView.sendSubviewToBack(backgroundView)
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(transportButtonsView)
        }
        
        buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.distribution = .fillEqually
        buttonContainer.spacing = 12
        buttonContainer.isUserInteractionEnabled = true
        transportButtonsView.addSubview(buttonContainer)
        
        buttonContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let transportOptions = ["car.fill", "bicycle", "tram.fill", "figure.walk"]
        transportButtons = []
        
        for (index, icon) in transportOptions.enumerated() {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: icon), for: .normal)
            button.tintColor = .white
            button.backgroundColor = .clear
            button.layer.cornerRadius = 25
            button.tag = index
            button.isUserInteractionEnabled = true
            button.addTarget(self, action: #selector(transportButtonTapped(_:)), for: .touchUpInside)
            transportButtons.append(button)
        }
        
        selectedTransportButton = transportButtons.first
        selectedTransportButton?.backgroundColor = .deepBlue
        
        for button in transportButtons {
            buttonContainer.addArrangedSubview(button)
        }
        updateTransportButtonsDisplay()
        self.transportBackgroundView = backgroundView
        
        return buttonsView
    }
    
    private func updateTransportButtonsDisplay() {
        if isExpanded {
            for button in transportButtons {
                button.isHidden = false
            }
            transportBackgroundView?.isHidden = false
            
            let buttonWidth: CGFloat = 50
            let buttonSpacing: CGFloat = 12
            let totalWidth = CGFloat(transportButtons.count) * buttonWidth + CGFloat(transportButtons.count - 1) * buttonSpacing
            transportButtonsViewWidthConstraint?.update(offset: totalWidth)
        } else {
            
            for button in transportButtons {
                button.isHidden = (button != selectedTransportButton)
            }
            
            transportBackgroundView?.isHidden = true
            transportButtonsViewWidthConstraint?.update(offset: 50)
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func transportButtonTapped(_ sender: UIButton) {
        if sender == selectedTransportButton {
            toggleTransportButtons()
        } else {
            selectedTransportButton?.backgroundColor = .clear
            selectedTransportButton = sender
            sender.backgroundColor = .deepBlue
            selectedTransportType = transportTypeForIndex(sender.tag)
            
            if let index = transportButtons.firstIndex(of: sender) {
                transportButtons.remove(at: index)
                transportButtons.insert(sender, at: 0)
            }
            
            for button in buttonContainer.arrangedSubviews {
                buttonContainer.removeArrangedSubview(button)
                button.removeFromSuperview()
            }
            for button in transportButtons {
                buttonContainer.addArrangedSubview(button)
            }
            
            isExpanded = false
            UIView.animate(withDuration: 0.3) {
                self.updateTransportButtonsDisplay()
                self.view.layoutIfNeeded()
            }
            
            updateMapForSelectedTransportType()
        }
    }
    
    @objc private func toggleTransportButtons() {
        isExpanded.toggle()
        UIView.animate(withDuration: 0.3) {
            self.updateTransportButtonsDisplay()
            self.view.layoutIfNeeded()
        }
    }
    
    private func transportTypeForIndex(_ index: Int) -> MKDirectionsTransportType {
        switch index {
        case 0:
            return .automobile
        case 1:
            return .walking
        case 2:
            return .transit
        case 3:
            return .walking
        default:
            return .automobile
        }
    }
    
    private func updateMapForSelectedTransportType() {
        guard let startCoordinate = locationManager.currentLocation?.coordinate else { return }

        let place = places[currentTargetIndex]
        let destinationCoordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        directionRequest.transportType = selectedTransportType

        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] (response, error) in
            guard let self = self, let response = response, error == nil else { return }

            let route = response.routes[0]
            DispatchQueue.main.async {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: self.currentTargetIndex)) as? MapTableViewCell {
                    cell.showMap(from: startCoordinate, to: destinationCoordinate, with: route)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? UITableView.automaticDimension : 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if mapVisibilityState[indexPath.section] ?? false {
            return 200
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        places.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < places.count else { return nil }
        
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let footerView = UIView()
        footerView.backgroundColor = .white
        footerView.layer.cornerRadius = 20
        footerView.layer.masksToBounds = true
        containerView.addSubview(footerView)
        
        footerView.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(10)
            make.bottom.equalTo(containerView).offset(-10)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
        }
        
        let placeLabel = UILabel()
        let place = places[section]
        placeLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 20)
        placeLabel.textColor = .deepBlue
        placeLabel.numberOfLines = 0
        footerView.addSubview(placeLabel)
        
        placeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview().offset(-60)
        }
        
        let completeButton = UIButton(type: .system)
        completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        completeButton.setImage(UIImage(systemName: "checkmark.circle"), for: .disabled)
        completeButton.tag = section
        completeButton.tintColor = .accent
        completeButton.addTarget(self, action: #selector(didTapCompleteButton(_:)), for: .touchUpInside)
        footerView.addSubview(completeButton)
        
        completeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        
        let descriptionLabel = UILabel()
        descriptionLabel.tag = 100 + section
        descriptionLabel.numberOfLines = 5
        descriptionLabel.lineSpacing = 3
        footerView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(placeLabel)
            make.top.equalTo(placeLabel.snp.bottom).offset(12)
            make.trailing.equalToSuperview().offset(-50)
        }
        descriptionLabel.font = UIFont(name: "NotoSerifHK-Bold", size: 14)
        
        let isCompleted = completedPlaceIds.contains(place.id)
        let isWithinRange = (section < buttonState.count) ? buttonState[section] : false
        
        if isCompleted {
            completeButton.isEnabled = true
            completeButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.circle.fill"), for: .normal)
            updateFooterViewForFlippedState(footerView, sectionIndex: section, place: place)
        } else {
            if section == currentTargetIndex && isWithinRange {
                
                completeButton.isEnabled = true
                completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            } else {
                
                completeButton.isEnabled = false
                completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            }
            placeLabel.text = place.name
            placeLabel.textColor = .deepBlue
        }
        
        footerViews[section] = footerView
        return containerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath) as? MapTableViewCell ?? MapTableViewCell()
        let place = places[indexPath.section]

        let isMapVisibleForSection = mapVisibilityState[indexPath.section] ?? false
        if isMapVisibleForSection {
            guard let startCoordinate = locationManager.currentLocation?.coordinate else { return cell }
            let destinationCoordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)

            // 建立路徑請求
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
            directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            directionRequest.transportType = selectedTransportType

            // 計算路徑
            let directions = MKDirections(request: directionRequest)
            directions.calculate { response, error in
                guard let response = response, error == nil else { return }

                let route = response.routes.first  // 取得第一條路徑
                DispatchQueue.main.async {
                    cell.showMap(from: startCoordinate, to: destinationCoordinate, with: route!)
                }
            }
        } else {
            cell.hideMap()
        }

        return cell
    }
    
    func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.register(MapTableViewCell.self, forCellReuseIdentifier: "MapCell")
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func didTapLocateButton(_ sender: UIButton) {
        isMapVisible.toggle()
        
        mapVisibilityState[currentTargetIndex] = isMapVisible
        
        sender.isSelected = isMapVisible
        if isMapVisible {
            sender.backgroundColor = .deepBlue
        } else {
            sender.backgroundColor = .systemGray4
        }
        
        let indexPath = IndexPath(row: 0, section: currentTargetIndex)
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
    
    func setupCompletedFooterView(footerView: UIView, sectionIndex: Int) {
        isFlipped[sectionIndex] = false
        footerView.backgroundColor = .systemGray5
        if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            placeLabel.text = places[sectionIndex].name
            placeLabel.textColor = .deepBlue
            if let descriptionLabel = footerView.subviews.first(where: { $0 is UILabel && $0 != placeLabel }) as? UILabel {
                descriptionLabel.text = ""
            }
        }
        
        if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
            completeButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.circle.fill"), for: .normal)
            completeButton.isEnabled = true
        }
    }
    
    @objc func didTapCompleteButton(_ sender: UIButton) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        guard let trip = trip else { return }
        
        let sectionIndex = sender.tag
        guard sectionIndex < places.count else { return }
        
        let place = places[sectionIndex]
        let placeId = place.id
        
        let isCurrentlyFlipped = isFlipped[sectionIndex] ?? false
        let isCompleted = completedPlaceIds.contains(placeId)
        
        if !isCompleted {
            FirebaseManager.shared.updateCompletedTripAndPlaces(for: userId, trip: trip, placeId: placeId) { success in
                if success {
                    DispatchQueue.main.async {
                        self.completedPlaceIds.append(placeId)
                        
                        if let footerView = self.footerViews[sectionIndex],
                           let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                            
                            self.mapVisibilityState[sectionIndex] = false
                            self.closeMapAndCollapseCell(at: sectionIndex)
                            
                            completeButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.circle.fill"), for: .normal)
                            
                            self.isFlipped[sectionIndex] = true
                            
                            UIView.transition(with: footerView, duration: 0.5, options: .transitionFlipFromRight, animations: {
                                self.updateFooterViewForFlippedState(footerView, sectionIndex: sectionIndex, place: place)
                            }, completion: nil)
                        }
                        
                        if sectionIndex + 1 < self.places.count {
                                self.expandNextCell(at: sectionIndex + 1)
                            
                        } else {
                            self.checkIfAllPlacesCompleted()
                        }
                        self.closeMapAndCollapseCell(at: sectionIndex)
                    }
                    
                    self.locationManager.startUpdatingLocation()
                    self.locationManager.onLocationUpdate = { [weak self] currentLocation in
                        guard let self = self else { return }
                        self.checkDistanceForCurrentTarget(from: currentLocation)
                    }
                    
                    if let currentLocation = self.locationManager.currentLocation {
                        self.checkDistanceForCurrentTarget(from: currentLocation)
                    }
                } else {
                }
            }
        } else {
            
            if let footerView = self.footerViews[sectionIndex] {
                self.startUpdatingLocationIfNeeded()
                
                self.isFlipped[sectionIndex]?.toggle()
                
                if let isFlipped = self.isFlipped[sectionIndex] {
                    UIView.transition(with: footerView, duration: 0.5, options: isFlipped ? [.transitionFlipFromRight] : [.transitionFlipFromLeft], animations: {
                        self.updateFooterViewForFlippedState(footerView, sectionIndex: sectionIndex, place: place)
                    }, completion: { _ in
                        self.closeMapAndCollapseCell(at: sectionIndex)
                    })
                } else {
                    self.isFlipped[sectionIndex] = false
                }
            }
        }
    }
    
    func startUpdatingLocationIfNeeded() {
        self.locationManager.startUpdatingLocation()
        self.locationManager.onLocationUpdate = { [weak self] currentLocation in
            guard let self = self else { return }
            self.checkDistanceForCurrentTarget(from: currentLocation)
        }
        
        if let currentLocation = self.locationManager.currentLocation {
            self.checkDistanceForCurrentTarget(from: currentLocation)
        }
    }
    
    func closeMapAndCollapseCell(at sectionIndex: Int) {
            mapVisibilityState[sectionIndex] = false
            self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: sectionIndex)], with: .fade)
            self.tableView.endUpdates()
        
        if let currentLocation = self.locationManager.currentLocation {
                self.checkDistanceForCurrentTarget(from: currentLocation)
            }
    }
    
    func expandNextCell(at sectionIndex: Int) {
        guard sectionIndex < places.count else { return }
        currentTargetIndex = sectionIndex
        if self.locationButton.isSelected {
            mapVisibilityState[sectionIndex] = true
        }
        let indexPath = IndexPath(row: 0, section: currentTargetIndex)
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: sectionIndex)], with: .fade)
    }

    func checkIfAllPlacesCompleted() {
        if completedPlaceIds.count == places.count {
            disableLocateButton()
        }
    }
    
    func disableLocateButton() {
        locationButton.isEnabled = false
        locationButton.backgroundColor = .systemGray4
    }
    
    func updateFooterViewForFlippedState(_ footerView: UIView, sectionIndex: Int, place: Place) {
        let isCurrentlyFlipped = isFlipped[sectionIndex] ?? false
        if isCurrentlyFlipped {
            if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                footerView.backgroundColor = .deepBlue
                if let poemPair = self.placePoemPairs.first(where: { $0.placeId == place.id }) {
                    placeLabel.text = poemPair.poemLine
                    placeLabel.textColor = .white
                    if let descriptionLabel = footerView.viewWithTag(100 + sectionIndex) as? UILabel {
                        if let savedSuggestion = savedSuggestions[place.id] {
                            descriptionLabel.text = savedSuggestion
                        } else {
                            descriptionLabel.text = "生成中..."
                            descriptionLabel.textColor = .backgroundGray
                            OpenAIManager.shared.fetchSuggestion(poemLine: poemPair.poemLine, placeName: place.name) { result in
                                switch result {
                                case .success(let suggestion):
                                    DispatchQueue.main.async {
                                        self.savedSuggestions[place.id] = suggestion
                                        descriptionLabel.text = suggestion
                                    }
                                case .failure(let error):
                                    DispatchQueue.main.async {
                                        descriptionLabel.text = "無法生成描述"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                completeButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.circle.fill"), for: .normal)
                completeButton.isEnabled = true
            }
        } else {
            footerView.backgroundColor = .systemGray5
            if let placeLabel = footerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                placeLabel.text = place.name
                placeLabel.textColor = .deepBlue
                
                if let descriptionLabel = footerView.subviews.first(where: { $0 is UILabel && $0 != placeLabel }) as? UILabel {
                    descriptionLabel.text = ""
                }
            }
            
            if let completeButton = footerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                if completedPlaceIds.contains(place.id) {
                    completeButton.setImage(UIImage(systemName: "arrowshape.turn.up.backward.circle.fill"), for: .normal)
                    completeButton.isEnabled = true
                } else {
                    let isWithinRange = buttonState[sectionIndex]
                    completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                    completeButton.isEnabled = isWithinRange
                }
            }
        }
    }
    
    func fetchPlacePoemPairs(for tripId: String, completion: @escaping ([PlacePoemPair]?) -> Void) {
        let db = Firestore.firestore()
        let tripRef = db.collection("trips").document(tripId)
        
        tripRef.getDocument { (document, error) in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil)
                return
            }
            
            if let placePoemPairsData = data["placePoemPairs"] as? [[String: Any]] {
                var placePoemPairs = [PlacePoemPair]()
                
                for pairData in placePoemPairsData {
                    if let placeId = pairData["placeId"] as? String,
                       let poemLine = pairData["poemLine"] as? String {
                        let placePoemPair = PlacePoemPair(placeId: placeId, poemLine: poemLine)
                        placePoemPairs.append(placePoemPair)
                    }
                }
                completion(placePoemPairs)
            } else {
                completion(nil)
            }
        }
    }
}
