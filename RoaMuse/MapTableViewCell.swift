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
    
    func showMap(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, with route: MKRoute) {
        mapView.isHidden = false

        // 清除舊的標註和路徑
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // 添加起點標註
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.coordinate = startCoordinate
//        mapView.addAnnotation(sourceAnnotation)

        // 添加終點標註
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destinationCoordinate
        mapView.addAnnotation(destinationAnnotation)

        // 添加路線覆蓋層
        mapView.addOverlay(route.polyline)

        // 調整地圖區域以適應路線
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
            animated: true
        )
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
