//
//  LocationManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var onLocationUpdate: ((CLLocation) -> Void)?
    var targetLocation: CLLocation?
    var currentLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func setTargetLocation(latitude: Double, longitude: Double) {
        targetLocation = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            onLocationUpdate?(location)
//            stopUpdatingLocation()
        } else {
            print("未獲取到有效位置數據")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("位置授權被拒絕或受限")
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置獲取失敗: \(error.localizedDescription)")
    }
}
