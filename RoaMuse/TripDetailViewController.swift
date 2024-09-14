//
//  TripDetailViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/14.
//

import Foundation
import UIKit

class TripDetailViewController: UIViewController {
    
    var trip: Trip?  // 存儲傳遞過來的資料
    var onTripReceivedFromHome: ((Trip) -> Void)?
    let placesStackView = UIStackView()
    private let dataManager = DataManager()
    private var placeName = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .backgroundGray)
        dataManager.loadPlacesJSONData()
        getPlaceNameByPlaceId()
        setupUI()
    }
    
    func getPlaceNameByPlaceId() {
        
        print(dataManager.places)
        
        guard let trip = trip else { return }
        
        for tripPlace in trip.places {
            
            for place in dataManager.places {
                
                if place.id == tripPlace {
                    
                    placeName.append(place.name)
                    
                }
                
            }
            
        }
        
    }
    
    func setupUI() {
        
        view.addSubview(placesStackView)
        
        placesStackView.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        
        placesStackView.axis = .vertical
        placesStackView.spacing = 30
        
        
        guard let trip = trip else { return }
        
        for place in placeName {
            let placeLabel = UILabel()
            placeLabel.textColor = .black
            placeLabel.text = place
            placesStackView.addArrangedSubview(placeLabel)
        }
        
    }
    
}
