//
//  MapTableViewCell.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/2.
//

import Foundation
import UIKit
import MapKit

class MapTableViewCell: UITableViewCell {
    
    let mapView = MKMapView()
    var lastUpdatedTime: Date?
    var regionUpdateTimer: Timer?
    
    // 添加属性
    private var isUserInteracting = false
    private var lastStartCoordinate: CLLocationCoordinate2D?
    private var lastDestinationCoordinate: CLLocationCoordinate2D?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupMapView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupMapView() {
        contentView.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mapView.isHidden = true
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none // 改为 .none
    }
    
    func showMap(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) {
        
        print("showMap called")
        
        if isUserInteracting {
                return
            }
            
            let coordinateThreshold: CLLocationDistance = 10.0
        if let lastStart = lastStartCoordinate, let lastDestination = lastDestinationCoordinate {
            let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            let lastStartLocation = CLLocation(latitude: lastStart.latitude, longitude: lastStart.longitude)
            let startDistance = startLocation.distance(from: lastStartLocation)
            
            let destinationLocation = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
            let lastDestinationLocation = CLLocation(latitude: lastDestination.latitude, longitude: lastDestination.longitude)
            let destDistance = destinationLocation.distance(from: lastDestinationLocation)
            
            if startDistance < coordinateThreshold && destDistance < coordinateThreshold {
                
                return
            }
        }

            
            // 更新上次坐标
            lastStartCoordinate = startCoordinate
            lastDestinationCoordinate = destinationCoordinate
        
        mapView.isHidden = false
        
        // 计算距离
        let userLocation = startCoordinate
        let destinationLocation = destinationCoordinate
        
        let distance = MKMapPoint(userLocation).distance(to: MKMapPoint(destinationLocation))
        
        let now = Date()
        if let lastUpdatedTime = lastUpdatedTime, now.timeIntervalSince(lastUpdatedTime) < 180 {
            return
        }
        
        let currentRegion = mapView.region
        let newRegion = MKCoordinateRegion(center: startCoordinate, latitudinalMeters: distance * 1.5, longitudinalMeters: distance * 1.5)
        
        let regionHasChanged = abs(currentRegion.center.latitude - newRegion.center.latitude) > 0.001 ||
            abs(currentRegion.center.longitude - newRegion.center.longitude) > 0.001
        
        if regionHasChanged {
            self.lastUpdatedTime = now
            let region = MKCoordinateRegion(center: startCoordinate, latitudinalMeters: distance * 1.5, longitudinalMeters: distance * 1.5)
            mapView.setRegion(region, animated: false)
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destinationCoordinate
        destinationAnnotation.title = "Destination"
        mapView.addAnnotation(destinationAnnotation)
        
        // 计算路线
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: startCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self, let route = response?.routes.first else { return }
            self.mapView.addOverlay(route.polyline) // 在地图上添加路线
        }
    }
    
    func hideMap() {
        mapView.isHidden = true
    }
}

extension MapTableViewCell: MKMapViewDelegate {
    // 绘制路线
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // 配置标注视图
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 对于用户位置，使用默认蓝点
        if annotation is MKUserLocation {
            return nil
        }
        
        // 对于其他标注，使用红色大头针
        if annotation is MKPointAnnotation {
            let identifier = "PinAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.pinTintColor = .red  // 红色大头针
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        
        return nil
    }
    
    // 监测用户交互
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        isUserInteracting = true
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        isUserInteracting = false
    }
}
