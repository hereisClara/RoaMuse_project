//
//  MapViewController.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/28.
//

import UIKit
import MapKit
import FirebaseFirestore
import Photos
import SideMenu

class MapViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let filterButton = UIButton(type: .system)
    var isSlidingViewVisible = false
    var backgroundMaskView: UIView!
    var placeTripDictionary = [String: PlaceTripInfo]()
    var mapView: MKMapView!
    var images: [UIImage] = []
    var slidingView: SlidingView!
    var fullScreenImageView: UIImageView!
    var currentImageIndex: Int = 0
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = ""
        self.navigationController?.isNavigationBarHidden = false
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.showsCompass = true
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        view.addSubview(mapView)
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Marker")
        
        loadCompletedPlacesAndAddAnnotations(selectedIndex: nil)
        
        setupFullScreenImageView()
        setupFilterButton()
        setupSlidingView()
    }
    
    func setupFilterButton() {
        
        let backgroundCircle = UIView()
        backgroundCircle.backgroundColor = UIColor.white.withAlphaComponent(0.7)  // 半透明白色
        backgroundCircle.layer.cornerRadius = 35  // 圓形（寬高一樣，半徑為寬/2）
        view.addSubview(backgroundCircle)
        
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)  // 圖標大小及粗細
        let iconImage = UIImage(systemName: "slider.horizontal.3", withConfiguration: imageConfig)
        filterButton.setImage(iconImage, for: .normal)
        filterButton.tintColor = .deepBlue  // 設定圖標顏色
        filterButton.backgroundColor = .clear  // 清除按鈕背景色
        filterButton.addTarget(self, action: #selector(toggleSlidingView), for: .touchUpInside)
        view.addSubview(filterButton)

        backgroundCircle.snp.makeConstraints { make in
            make.width.height.equalTo(70)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
        }

        filterButton.snp.makeConstraints { make in
            make.center.equalTo(backgroundCircle)
            make.width.height.equalTo(40) 
        }
    }
    
    @objc func toggleSlidingView() {
        
        isSlidingViewVisible.toggle()
        sideMenuController?.revealMenu()
        UIView.animate(withDuration: 0.3) {
            self.slidingView.isHidden = !self.isSlidingViewVisible
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func setupSlidingView() {
        slidingView = SlidingView(frame: CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 600), parentViewController: self)
        view.addSubview(slidingView)
    }
    
    func loadCompletedPlacesAndAddAnnotations(selectedIndex: Int?) {
        guard let userId = userId else { return }

        self.placeTripDictionary = [:]
        let userRef = Firestore.firestore().collection("users").document(userId)

        userRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("獲取 user completedPlace 失敗: \(error.localizedDescription)")
                return
            }

            guard let document = documentSnapshot, let data = document.data(),
                  let completedPlace = data["completedPlace"] as? [[String: Any]] else {
                print("錯誤: 無法解析 completedPlace 資料")
                return
            }

            let group = DispatchGroup()  // DispatchGroup 用來同步等待所有請求完成
            var filteredPlaceTripDictionary = [String: PlaceTripInfo]()

            for placeEntry in completedPlace {
                if let placeIds = placeEntry["placeIds"] as? [String], let tripId = placeEntry["tripId"] as? String {
                    for placeId in placeIds {
                        group.enter()
                        let tripRef = Firestore.firestore().collection("trips").document(tripId)

                        tripRef.getDocument { snapshot, error in
                            defer { group.leave() }

                            if let error = error {
                                print("獲取 trip 失敗: \(error.localizedDescription)")
                                return
                            }

                            guard let tripData = snapshot?.data() else { return }

                            if selectedIndex == nil || tripData["tag"] as? Int == selectedIndex {
                                if var placeTripInfo = filteredPlaceTripDictionary[placeId] {
                                    placeTripInfo.tripIds.append(tripId)
                                    filteredPlaceTripDictionary[placeId] = placeTripInfo
                                } else {
                                    filteredPlaceTripDictionary[placeId] = PlaceTripInfo(placeId: placeId, tripIds: [tripId])
                                }
                            }
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.placeTripDictionary = filteredPlaceTripDictionary  // 設定整理後的資料
                print("完成的地點: ", self.placeTripDictionary.keys)
                
                // 呼叫 fetchPlaces 來標註地點
                self.fetchPlaces(for: Array(filteredPlaceTripDictionary.keys))
            }
        }
    }

    func fetchPlaces(for placeIds: [String]) {
        mapView.removeAnnotations(mapView.annotations)

        let placesRef = Firestore.firestore().collection("places")
        let dispatchGroup = DispatchGroup()

        for placeId in placeIds {
            dispatchGroup.enter()

            placesRef.document(placeId).getDocument { documentSnapshot, error in
                defer { dispatchGroup.leave() }  // 確保每次請求結束都會呼叫 leave()

                if let error = error {
                    print("獲取地點失敗: \(error.localizedDescription)")
                    return
                }

                guard let document = documentSnapshot, let data = document.data(),
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let placeName = data["name"] as? String else {
                    print("解析地點資料失敗")
                    return
                }

                let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                print("加入地點: \(placeName), ID: \(placeId)")

                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = placeName
                annotation.subtitle = placeId

                self.mapView.addAnnotation(annotation)
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("所有標註點已經添加")
        }
    }
    
    func fetchPhotos(for location: CLLocation, radius: Double, completion: @escaping ([UIImage]) -> Void) {
        let fetchOptions = PHFetchOptions()
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var images = [UIImage]()
        
        let imageManager = PHCachingImageManager()
        let targetSize = CGSize(width: 300, height: 300)
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        
        assets.enumerateObjects { asset, index, stop in
            if let assetLocation = asset.location {
                let distance = assetLocation.distance(from: location)
                if distance <= radius {
                    imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                        if let image = image {
                            images.append(image)
                        }
                    }
                }
            }
        }
        completion(images)
    }
    
    func requestPhotoLibraryPermissions(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
        default:
            completion(false)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
                return nil
            }
        
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: clusterAnnotation)
            return clusterView
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Marker", for: annotation) as? MKMarkerAnnotationView {
            
            annotationView.clusteringIdentifier = "clusterID"
            
//            annotationView.canShowCallout = true
            
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = infoButton
            
            annotationView.markerTintColor = .red // 設定大頭針的顏色
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation,
              let placeId = annotation.subtitle ?? annotation.title else {
            print("No valid annotation selected")
            return
        }

        slidingView.currentPlaceId = placeId

        guard let placeTripInfo = placeTripDictionary[placeId ?? ""] else {
            print("No matching tripIds found for placeId: \(placeId)")
            return
        }

        slidingView.tripIds = placeTripInfo.tripIds
        slidingView.tableView.reloadData()

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        let annotationLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        requestPhotoLibraryPermissions { granted in
            if granted {
                self.fetchPhotos(for: annotationLocation, radius: 500) { images in
                    self.slidingView.images = images
                    dispatchGroup.leave()
                }
            } else {
                print("Photo library permissions denied")
                dispatchGroup.leave()
            }
        }

        // 詩句資料請求
        dispatchGroup.enter()
        slidingView.fetchPoemTitleAndPoemLine(tripId: placeTripInfo.tripIds.first ?? "") { poemTitle, poemLine in
            DispatchQueue.main.async {
                // 你可以在這裡更新相關 UI 或變數
                print("詩名: \(poemTitle), 詩句: \(poemLine)")
                dispatchGroup.leave()  // 當詩句資料完成時再呼叫 leave()
            }
        }

        // 所有資料獲取完成後顯示 slidingView 並更新 UI
        dispatchGroup.notify(queue: .main) {
            self.slidingView.tableView.reloadData()
            self.centerMapOnAnnotation(annotation: annotation)
            self.showSlidingView()
        }
    }
    
    func centerMapOnUserLocation(userLocation: CLLocation) {
        let regionRadius: CLLocationDistance = 50000  // 50公里
        let coordinateRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
//    MARK: map center
    func centerMapOnAnnotation(annotation: MKAnnotation) {
        let regionRadius: CLLocationDistance = 5000  // 縮放半徑，根據需求調整

        let mapViewHeight = mapView.bounds.height
        let mapViewWidth = mapView.bounds.width

        let yOffsetInPoints = mapViewHeight / 4  // 嘗試將其設為 1/4 或其他值

        // 3. 將地理座標轉換為地圖上的螢幕點
        let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)

        // 4. 計算新的中心點的螢幕座標，向上移動
        let newCenterPoint = CGPoint(x: mapViewWidth / 2, y: annotationPoint.y - yOffsetInPoints)

        // 5. 將新的螢幕座標轉換回地理座標，設為地圖的新中心點
        let newCenterCoordinate = mapView.convert(newCenterPoint, toCoordinateFrom: mapView)

        // 6. 設定地圖的新區域，並放大縮小顯示
        let region = MKCoordinateRegion(center: newCenterCoordinate,
                                        latitudinalMeters: regionRadius * 2,
                                        longitudinalMeters: regionRadius * 2)

        mapView.setRegion(region, animated: true)
    }

    func showSlidingView() {
        // 添加背景遮罩视图
        print("showSlidingView called")
        slidingView.isHidden = false

        backgroundMaskView = UIView(frame: view.bounds)
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.insertSubview(backgroundMaskView, belowSubview: slidingView)
        print("SlidingView frame:", slidingView.frame)
        print("SlidingView hidden:", slidingView.isHidden)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideSlidingView))
        backgroundMaskView.addGestureRecognizer(tapGesture)
        
        UIView.animate(withDuration: 0.3) {
            self.slidingView.frame.origin.y = self.view.bounds.height - 600
        }
    }
    
    @objc func hideSlidingView() {
        // 下滑隐藏 slidingView
        UIView.animate(withDuration: 0.3, animations: {
            self.slidingView.frame.origin.y = self.view.bounds.height
        }) { _ in
            // 动画完成后移除遮罩视图
            self.backgroundMaskView.removeFromSuperview()
        }
    }
    
    func getTripId(from annotation: MKAnnotation) -> [String]? {
        
        guard let placeId = annotation.subtitle as? String else {
            return []
        }
        
        guard let placeTripInfo = placeTripDictionary[placeId] else {
            return []
        }
        
        return placeTripInfo.tripIds
    }
    
    func fetchTripAndPoemData(for tripId: String, completion: @escaping (String, String) -> Void) {
        let tripsRef = Firestore.firestore().collection("trips").document(tripId)
        
        // 根據 tripId 查詢對應的 trip 資料
        tripsRef.getDocument { (document, error) in
            if let error = error {
                print("獲取行程資料失敗: \(error.localizedDescription)")
                return
            }
            
            guard let tripData = document?.data(), let poemId = tripData["poemId"] as? String else {
                print("找不到相關行程資料或詩的ID")
                return
            }
            
            // 根據 poemId 查詢詩的名稱與作者
            let poemsRef = Firestore.firestore().collection("poems").document(poemId)
            poemsRef.getDocument { (document, error) in
                if let error = error {
                    print("獲取詩資料失敗: \(error.localizedDescription)")
                    return
                }
                
                let poemTitle = document?.get("title") as? String ?? "未知詩名"
                let poemAuthor = document?.get("poetry") as? String ?? "未知作者"
                
                // 傳回詩的名稱與作者
                completion(poemTitle, poemAuthor)
            }
        }
    }
    
    func showPhotos(_ images: [UIImage]) {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "photoCell")
        
        self.view.addSubview(collectionView)
        self.images = images  // 更新圖片
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FullScreenPhotoCell", for: indexPath)
        
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.image = images[indexPath.row]
        cell.contentView.addSubview(imageView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        displayFullScreenImage(at: indexPath.row)
    }
}

extension MapViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return scrollView.subviews.first as? UIImageView
    }
}

extension MapViewController {
    
    func setupFullScreenImageView() {
        fullScreenImageView = UIImageView(frame: view.bounds)
        fullScreenImageView.contentMode = .scaleAspectFit
        fullScreenImageView.backgroundColor = .black
        fullScreenImageView.isUserInteractionEnabled = true
        fullScreenImageView.alpha = 0
        
        // 添加手勢識別器
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeToNextImage))
        swipeLeft.direction = .left
        fullScreenImageView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeToPreviousImage))
        swipeRight.direction = .right
        fullScreenImageView.addGestureRecognizer(swipeRight)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFullScreenImageView))
        fullScreenImageView.addGestureRecognizer(tapGesture)
        
        view.addSubview(fullScreenImageView)
    }
    
    @objc func swipeToNextImage() {
        // 確保我們不會超出圖片陣列的範圍
        if currentImageIndex < images.count - 1 {
            currentImageIndex += 1  // 更新到下一張圖片
            fullScreenImageView.image = images[currentImageIndex]  // 更新圖片
        } else {
            print("已經是最後一張圖片")
        }
    }
    
    // 處理切換到上一張圖片的邏輯
    @objc func swipeToPreviousImage() {
        // 確保我們不會低於圖片陣列的範圍
        if currentImageIndex > 0 {
            currentImageIndex -= 1  // 回到上一張圖片
            fullScreenImageView.image = images[currentImageIndex]  // 更新圖片
        } else {
            print("已經是第一張圖片")
        }
    }
    
    func displayFullScreenImage(at index: Int) {
        currentImageIndex = index
        fullScreenImageView.image = images[index]
        
        UIView.animate(withDuration: 0.3) {
            self.fullScreenImageView.alpha = 1
        }
    }
    
    @objc func dismissFullScreenImageView() {
        UIView.animate(withDuration: 0.3) {
            self.fullScreenImageView.alpha = 0  // 隱藏全螢幕視圖
        }
    }
}
