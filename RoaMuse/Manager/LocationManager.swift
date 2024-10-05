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
    }

    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func startUpdatingHeading() {
            locationManager.startUpdatingHeading()  // 啟動方向更新
        }

        func stopUpdatingHeading() {
            locationManager.stopUpdatingHeading()  // 停止方向更新
        }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("授权状态发生变化：\(status.rawValue)")
        onAuthorizationChange?(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager(_:didUpdateLocations:) called")
        if let location = locations.first {
            print("位置更新：\(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.currentLocation = location
            onLocationUpdate?(location)  // 确保调用闭包
        } else {
            print("未获取到有效位置数据")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            onHeadingUpdate?(newHeading)  // 使用新的方向數據
        }
}
