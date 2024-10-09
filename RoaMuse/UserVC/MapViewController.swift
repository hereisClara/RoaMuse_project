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

class MapViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var backgroundMaskView: UIView!
    var placeTripDictionary = [String: PlaceTripInfo]()
    var mapView: MKMapView!
    var images: [UIImage] = []  // 定義存放照片的屬性
    var slidingView: SlidingView!
    var fullScreenImageView: UIImageView!
    var currentImageIndex: Int = 0
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        navigationItem.backButtonTitle = ""
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        view.addSubview(mapView)
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Marker")
        
        loadCompletedPlacesAndAddAnnotations()
        setupSlidingView()
        setupFullScreenImageView()
    }
    
    func setupSlidingView() {
        slidingView = SlidingView(frame: CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 600), parentViewController: self)
        view.addSubview(slidingView)
    }
    
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
            print("切換到下一張圖片，當前索引: \(currentImageIndex)")
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
            print("切換到上一張圖片，當前索引: \(currentImageIndex)")
        } else {
            print("已經是第一張圖片")
        }
    }
    
    // Function to display the image in full screen when a thumbnail is tapped
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
    
    func loadCompletedPlacesAndAddAnnotations() {
        guard let userId = userId else {
            print("錯誤: 無法從 UserDefaults 獲取 userId，請確認 userId 已正確存入 UserDefaults")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        // 從 Firestore 獲取 user 的 completedPlace
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
            for placeEntry in completedPlace {
                if let placeIds = placeEntry["placeIds"] as? [String], let tripId = placeEntry["tripId"] as? String {
                    for placeId in placeIds {
                        if var placeTripInfo = self.placeTripDictionary[placeId] {
                            placeTripInfo.tripIds.append(tripId)
                            self.placeTripDictionary[placeId] = placeTripInfo
                        } else {
                            self.placeTripDictionary[placeId] = PlaceTripInfo(placeId: placeId, tripIds: [tripId])
                        }
                    }
                }
            }
            
            let uniquePlaceIds = Array(self.placeTripDictionary.keys)
            self.fetchPlaces(for: uniquePlaceIds)
            
            for (placeId, placeTripInfo) in self.placeTripDictionary {
                print("============")
                print("Place ID: \(placeId), Trip IDs: \(placeTripInfo.tripIds)")
            }
        }
    }
    
    func fetchPlaces(for placeIds: [String]) {
        let placesRef = Firestore.firestore().collection("places")
        let dispatchGroup = DispatchGroup()
        
        for placeId in placeIds {
            dispatchGroup.enter()
            
            placesRef.document(placeId).getDocument { documentSnapshot, error in
                if let error = error {
                    dispatchGroup.leave()
                    return
                }
                
                guard let document = documentSnapshot, let data = document.data(),
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let placeName = data["name"] as? String else {
                    dispatchGroup.leave()
                    return
                }
                
                let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = placeName
                annotation.subtitle = placeId // 確保此處設置 placeId
                self.mapView.addAnnotation(annotation)
                dispatchGroup.leave()
            }
        }
        
        // 確保所有的查詢完成後再進行後續處理
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
    
    // 設置標註點視圖的 cluster 屬性
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 如果是 cluster（聚簇標註點），使用內建的 cluster 視圖
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: clusterAnnotation)
            return clusterView
        }
        
        // 如果是普通的標註點
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Marker", for: annotation) as? MKMarkerAnnotationView {
            // 設置 clusteringIdentifier 為 "clusterID" 以支持群組
            annotationView.clusteringIdentifier = "clusterID"
            
            // 啟用懸浮泡泡視窗
            annotationView.canShowCallout = true
            
            // 添加右側的詳細按鈕 (右側的附屬視圖)
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = infoButton
            
            // 可在此處根據 annotation 資訊設置不同的圖片或顯示風格
            annotationView.markerTintColor = .blue // 設定大頭針的顏色
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            if let placeId = annotation.subtitle ?? annotation.title {
                print("Found placeId: \(placeId)")
                slidingView.currentPlaceId = placeId
                if let placeTripInfo = placeTripDictionary[placeId ?? ""] {
                    let tripIds = placeTripInfo.tripIds
                    
                    slidingView.tripIds = tripIds
                    slidingView.tableView.reloadData()
                    let annotationLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                    requestPhotoLibraryPermissions { granted in
                        if granted {
                            self.fetchPhotos(for: annotationLocation, radius: 500) { images in
                                print("Fetched \(images.count) images")
                                DispatchQueue.main.async {
                                    self.slidingView.images = images
                                    self.slidingView.tableView.reloadData()  // 刷新 tableView
                                    
                                    print("Images updated in slidingView and tableView reloaded")
                                    
                                    self.centerMapOnAnnotation(annotation: annotation)
                                    print("Map centered on annotation")
                                    
                                    print("Calling showSlidingView")
                                    self.showSlidingView()
                                }
                            }
                        } else {
                            print("Photo library permissions denied")
                        }
                    }
                } else {
                    print("No matching tripIds found for placeId: \(placeId)")
                }
            } else {
                print("No placeId found in annotation title or subtitle")
            }
        } else {
            print("No annotation selected")
        }
    }

    func centerMapOnAnnotation(annotation: MKAnnotation) {
        
        var mapCenter = annotation.coordinate
        let mapRect = mapView.visibleMapRect
        let mapHeight = mapRect.size.height
        let yOffset = mapHeight / 4
        
        let currentCenter = mapView.centerCoordinate
        
        let adjustedCenter = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mapCenter.latitude - yOffset / mapHeight, longitude: currentCenter.longitude), span: mapView.region.span)
        
        mapView.setRegion(adjustedCenter, animated: true)
    }
    
    func showSlidingView() {
        // 添加背景遮罩视图
        print("showSlidingView called")
        backgroundMaskView = UIView(frame: view.bounds)
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.3)  // 半透明背景
        view.insertSubview(backgroundMaskView, belowSubview: slidingView)
        
        // 添加点击手势识别器，点击遮罩隐藏 slidingView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideSlidingView))
        backgroundMaskView.addGestureRecognizer(tapGesture)
        
        // 上滑显示 slidingView
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
        // 解包 annotation.subtitle 並確保其為非 nil 值
        guard let placeId = annotation.subtitle as? String else {
            return []
        }
        
        // 從 placeTripDictionary 中獲取對應的 tripIds
        guard let placeTripInfo = placeTripDictionary[placeId] else {
            return []
        }
        
        // 假設你需要返回第一個 tripId，如果有多個 tripId 可以根據需求進行修改
        return placeTripInfo.tripIds
    }
    
    
    func showPoemAlert(title: String, author: String) {
        let alertController = UIAlertController(title: "詩", message: "詩名: \(title)\n作者: \(author)", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確認", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
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
        // Tap to show full-screen image
        displayFullScreenImage(at: indexPath.row)
    }
}

extension MapViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return scrollView.subviews.first as? UIImageView
    }
}
