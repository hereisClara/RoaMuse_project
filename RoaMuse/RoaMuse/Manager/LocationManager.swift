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
    var onHeadingUpdate: ((CLHeading) -> Void)?
    var currentLocation: CLLocation?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        print("requestWhenInUseAuthorization")
    }

    func requestLocation() {
        locationManager.requestLocation()
        print("request location")
    }
    
    func startUpdatingHeading() {
            locationManager.startUpdatingHeading()
        }

        func stopUpdatingHeading() {
            locationManager.stopUpdatingHeading()
        }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onAuthorizationChange?(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("位置更新：\(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.currentLocation = location
            onLocationUpdate?(location)
        } else {
            print("未獲取到有效位置數據")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置獲取失敗: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            onHeadingUpdate?(newHeading) 
        }
}
