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
        
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestWhenInUseAuthorization() {
            locationManager.requestWhenInUseAuthorization()
        }
    
    func requestLocation() {
        locationManager.requestLocation()
    }

    
    func setTargetLocation(latitude: Double, longitude: Double) {
        targetLocation = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("位置更新：\(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.currentLocation = location
            self.onLocationUpdate?(location)
            // 只在授权后开始定位，因此无需再次停止
        } else {
            print("未获取到有效位置数据")
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
//            locationManager.startUpdatingLocation()
            print("位置授权已获得")
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
