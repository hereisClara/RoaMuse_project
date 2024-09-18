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

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        print("位置更新已啟動")
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        print("位置更新已停止")
        locationManager.stopUpdatingLocation()
    }
    
    func setTargetLocation(latitude: Double, longitude: Double) {
        targetLocation = CLLocation(latitude: latitude, longitude: longitude)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
                print("獲取到位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                onLocationUpdate?(location)
                stopUpdatingLocation()
            } else {
                print("未獲取到有效位置數據")
            }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("位置授權已獲得")
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

//import Foundation
//import CoreLocation
//
//class LocationManager: NSObject, CLLocationManagerDelegate {
//    
//    let locationManager = CLLocationManager()
//    var onLocationUpdate: ((CLLocation) -> Void)?
//    var targetLocation: CLLocation?
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//    }
//    
//    func setTargetLocation(latitude: Double, longitude: Double) {
//        targetLocation = CLLocation(latitude: latitude, longitude: longitude)
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.first, let targetLocation = targetLocation {
//            let distance = location.distance(from: targetLocation)
//            print("距離目標地點: \(distance) 公尺")
//            onLocationUpdate?(location)
//            locationManager.stopUpdatingLocation()
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Error getting location: \(error.localizedDescription)")
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        switch status {
//        case .notDetermined:
//            print("用戶尚未決定是否授權")
//        case .restricted, .denied:
//            print("用戶拒絕或受限")
//        case .authorizedWhenInUse, .authorizedAlways:
//            print("已授權")
//        @unknown default:
//            print("未知授權狀態")
//        }
//    }
//}
//
