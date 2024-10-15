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
    var images: [UIImage] = []  // 定義存放照片的屬性
//    let menuVC = MenuViewController()
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
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        view.addSubview(mapView)
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Marker")
        
//        menuVC.delegate = self
        loadCompletedPlacesAndAddAnnotations(selectedIndex: nil)
        
        setupFullScreenImageView()
        setupFilterButton()
        setupSlidingView()
    }
    
    func setupFilterButton() {
            filterButton.setTitle("篩選", for: .normal)
            filterButton.setTitleColor(.white, for: .normal)
            filterButton.backgroundColor = .systemBlue
            filterButton.layer.cornerRadius = 10
            filterButton.translatesAutoresizingMaskIntoConstraints = false
            filterButton.addTarget(self, action: #selector(toggleSlidingView), for: .touchUpInside)

            view.addSubview(filterButton)
            
            NSLayoutConstraint.activate([
                filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                filterButton.widthAnchor.constraint(equalToConstant: 100),
                filterButton.heightAnchor.constraint(equalToConstant: 50)
            ])
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

            // 遍歷所有的 completedPlace 並發起 trip 資料的請求
            for placeEntry in completedPlace {
                if let placeIds = placeEntry["placeIds"] as? [String], let tripId = placeEntry["tripId"] as? String {
                    for placeId in placeIds {
                        group.enter()
                        let tripRef = Firestore.firestore().collection("trips").document(tripId)

                        tripRef.getDocument { snapshot, error in
                            defer { group.leave() }  // 確保每次請求結束都會呼叫 leave()

                            if let error = error {
                                print("獲取 trip 失敗: \(error.localizedDescription)")
                                return
                            }

                            guard let tripData = snapshot?.data() else { return }

                            // 檢查 trip 的 tag 是否符合 selectedIndex
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

            // 當所有請求完成時執行
            group.notify(queue: .main) {
                self.placeTripDictionary = filteredPlaceTripDictionary  // 設定整理後的資料
                print("完成的地點: ", self.placeTripDictionary.keys)
                
                // 呼叫 fetchPlaces 來標註地點
                self.fetchPlaces(for: Array(filteredPlaceTripDictionary.keys))
            }
        }
    }

    func fetchPlaces(for placeIds: [String]) {
        print("fetch")

        // 移除所有現有的標註
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

        // 所有地點資料下載完成後
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
        
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            let clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: clusterAnnotation)
            return clusterView
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Marker", for: annotation) as? MKMarkerAnnotationView {
            
            annotationView.clusteringIdentifier = "clusterID"
            
            annotationView.canShowCallout = true
            
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = infoButton
            
            annotationView.markerTintColor = .blue // 設定大頭針的顏色
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            if let placeId = annotation.subtitle ?? annotation.title {
                slidingView.currentPlaceId = placeId
                if let placeTripInfo = placeTripDictionary[placeId ?? ""] {
                    let tripIds = placeTripInfo.tripIds
                    
                    slidingView.tripIds = tripIds
                    slidingView.tableView.reloadData()
                    let annotationLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                    requestPhotoLibraryPermissions { granted in
                        if granted {
                            self.fetchPhotos(for: annotationLocation, radius: 500) { images in
                                DispatchQueue.main.async {
                                    self.slidingView.images = images
                                    self.slidingView.tableView.reloadData()  // 刷新 tableView
                                    
                                    self.centerMapOnAnnotation(annotation: annotation)
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
        backgroundMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.insertSubview(backgroundMaskView, belowSubview: slidingView)
        
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
