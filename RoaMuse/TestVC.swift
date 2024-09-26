import Foundation
import UIKit
import CoreML
import MapKit
import CoreLocation

class TestVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    let button = UIButton()
    let textView = UITextView()
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    
    var foundLocations: [CLLocationCoordinate2D] = []
    var allRouteSteps: [String] = []
    
    let keywordCategoryMap: [String: [MKPointOfInterestCategory]] = [
        "海灘": [.beach],
        "森林": [.park],
        "山區": [.park],
        "河流": [.park],
        "湖泊": [.park],
        "高樓": [.park],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        view.backgroundColor = .systemGray3
        setupUI()
    }
    
    func setupUI() {
        // 設置 textView
        textView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 100)
        textView.backgroundColor = .white
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.layer.cornerRadius = 8
        view.addSubview(textView)
        
        // 設置 button
        button.setTitle("分析詩詞", for: .normal)
        button.frame = CGRect(x: (view.frame.width - 120) / 2, y: 220, width: 120, height: 50)
        button.addTarget(self, action: #selector(analyzeText), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        view.addSubview(button)
        
        // 設置 mapView
        mapView.frame = CGRect(x: 20, y: 280, width: view.frame.width - 40, height: 300)
        mapView.delegate = self
        view.addSubview(mapView)
    }
    
    @objc func analyzeText() {
        let inputText = textView.text ?? ""
        guard !inputText.isEmpty else {
            showAlert(title: "輸入錯誤", message: "請輸入文本以進行分析。")
            return
        }
        let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let model = try? poemLocationNLP3(configuration: .init()) else {
            showAlert(title: "錯誤", message: "無法加載 NLP 模型。")
            return
        }
        var allResults = [String]()
        for segment in textSegments {
            do {
                let prediction = try model.prediction(text: segment)
                let landscape = prediction.label
                allResults.append(landscape)
            } catch {
                print("分析失敗：\(error.localizedDescription)")
            }
        }
        showResult(landscapes: allResults)
    }
    
    func showResult(landscapes: [String]) {
        let uniqueLandscapes = Array(Set(landscapes))
        searchPlacesSequentially(forKeywords: uniqueLandscapes)
    }
    
    func searchPlacesSequentially(forKeywords keywords: [String]) {
        guard let userLocation = locationManager.location?.coordinate else {
            showAlert(title: "定位錯誤", message: "無法取得您的位置，請檢查定位服務是否已啟用。")
            return
        }
        var currentLocation = userLocation
        foundLocations = []
        allRouteSteps = []
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        let dispatchGroup = DispatchGroup()
        
        func searchNextKeyword(index: Int) {
            if index >= keywords.count {
                dispatchGroup.notify(queue: .main) {
                    self.plotRoutes() // 將交通細節打印到 log 中
                }
                return
            }
            
            let keyword = keywords[index]
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = keyword
            let searchRegion = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 5000, longitudinalMeters: 5000)
            request.region = searchRegion
            if let categories = keywordCategoryMap[keyword], !categories.isEmpty {
                request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
            } else {
                request.pointOfInterestFilter = nil
            }
            let search = MKLocalSearch(request: request)
            
            dispatchGroup.enter()
            search.start { (response, error) in
                defer { dispatchGroup.leave() }
                if let error = error {
                    print("搜尋失敗：\(error.localizedDescription)")
                    self.addAnnotation(for: keyword, name: nil, address: nil, coordinate: nil)
                    searchNextKeyword(index: index + 1)
                    return
                }
                
                if let mapItems = response?.mapItems {
                    let filteredItems = mapItems.filter { item in
                        let name = item.name?.lowercased() ?? ""
                        return !name.contains("restaurant") && !name.contains("café") && !name.contains("coffee")
                    }
                    
                    if let closestItem = filteredItems.first {
                        let name = closestItem.name ?? "無名稱"
                        let address = closestItem.placemark.title ?? "無地址"
                        self.addAnnotation(for: keyword, name: name, address: address, coordinate: closestItem.placemark.coordinate)
                        self.foundLocations.append(closestItem.placemark.coordinate)
                        currentLocation = closestItem.placemark.coordinate
                        
                        let alertMessage = "地點名稱: \(name)\n地景關鍵詞: \(keyword)"
                        self.showAlert(title: "地點與地景分析", message: alertMessage)
                    } else {
                        self.addAnnotation(for: keyword, name: nil, address: nil, coordinate: nil)
                    }
                }

                
                searchNextKeyword(index: index + 1)
            }
        }
        
        searchNextKeyword(index: 0)
    }
    
    func addAnnotation(for keyword: String, name: String?, address: String?, coordinate: CLLocationCoordinate2D?) {
        let annotation = MKPointAnnotation()
        annotation.title = name ?? "無名稱"
        annotation.subtitle = address ?? "無地址"
        if let coord = coordinate {
            annotation.coordinate = coord
        } else {
            annotation.coordinate = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        mapView.addAnnotation(annotation)
    }
    
    func plotRoutes() {
        guard foundLocations.count > 1 else {
            showAlert(title: "路線規劃", message: "找到的地點不足以規劃路線。")
            return
        }
        
        let dispatchGroup = DispatchGroup()
        allRouteSteps = []
        
        for num in 0..<(foundLocations.count - 1) {
            let source = foundLocations[num]
            let destination = foundLocations[num + 1]
            let request = MKDirections.Request()
            let sourcePlacemark = MKPlacemark(coordinate: source)
            let destinationPlacemark = MKPlacemark(coordinate: destination)
            request.source = MKMapItem(placemark: sourcePlacemark)
            request.destination = MKMapItem(placemark: destinationPlacemark)
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            dispatchGroup.enter()
            directions.calculate { (response, error) in
                defer { dispatchGroup.leave() }
                if let error = error {
                    print("路線規劃失敗：\(error.localizedDescription)")
                    return
                }
                if let route = response?.routes.first {
                    self.mapView.addOverlay(route.polyline)
                    
                    // 將交通細節打印到 log 中
                    print("從 \(self.getLocationName(coordinate: source)) 到 \(self.getLocationName(coordinate: destination))")
                    for step in route.steps {
                        print(step.instructions)
                    }
                    
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 100, left: 20, bottom: 100, right: 20), animated: true)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("路線規劃完成")
        }
    }

    
    func getLocationName(coordinate: CLLocationCoordinate2D) -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var name = "未知地點"
        let semaphore = DispatchSemaphore(value: 0)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                if let locality = placemark.locality {
                    name = locality
                } else if let namePlacemarks = placemark.name {
                    name = namePlacemarks
                }
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5)
        return name
    }
    
    func showRouteSteps() {
        let stepsText = allRouteSteps.joined(separator: "\n")
        showAlert(title: "路線步驟", message: stepsText)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            mapView.setRegion(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showAlert(title: "定位錯誤", message: "無法取得您的位置，請檢查定位服務是否已啟用。")
    }
}

extension TestVC: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // 您可以在這裡添加即時文本分析的功能（如果需要）
    }
}
