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
        mapView.userTrackingMode = .none
    }
    
    func showMap(from startCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D, with route: MKRoute) {
        mapView.isHidden = false

        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.coordinate = startCoordinate

        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destinationCoordinate
        mapView.addAnnotation(destinationAnnotation)

        mapView.addOverlay(route.polyline)

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
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if annotation is MKPointAnnotation {
            let identifier = "PinAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.pinTintColor = .red
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        isUserInteracting = true
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        isUserInteracting = false
    }
}
