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
    
    var placeTripDictionary = [String: PlaceTripInfo]()
    var mapView: MKMapView!
    var images: [UIImage] = []  // 定義存放照片的屬性
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        view.addSubview(mapView)
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Marker")
        
        loadCompletedPlacesAndAddAnnotations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
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
            
            // 使用字典來存儲 placeId 和對應的 tripIds
            
            
            // 遍歷 completedPlace，提取 placeIds 和對應的 tripId
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
                
                // 添加標註點
                let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = placeName
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

        // 從相簿中提取所有帶有地理位置信息的照片
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

        // 返回篩選後的照片
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
            // 獲取對應的 tripIds，這裡我們只顯示第一個 tripId
            if let tripIds = getTripId(from: annotation), let firstTripId = tripIds.first {
                // 查詢詩的資訊並顯示
                fetchTripAndPoemData(for: firstTripId) { poemTitle, poemAuthor in
                    DispatchQueue.main.async {
                        // 顯示彈出泡泡
                        let message = "詩名: \(poemTitle)\n作者: \(poemAuthor)"
                        let calloutView = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                        calloutView.text = message
                        calloutView.numberOfLines = 0
                        calloutView.textAlignment = .center
                        calloutView.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
                        calloutView.layer.cornerRadius = 8
                        calloutView.layer.borderWidth = 1
                        calloutView.layer.borderColor = UIColor.lightGray.cgColor
                        calloutView.clipsToBounds = true

                        // 將 calloutView 設置為 annotationView 的 detailCalloutAccessoryView
                        view.detailCalloutAccessoryView = calloutView
                    }
                }
            } else {
                print("無法找到對應的 tripId")
            }
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

    // UICollectionViewDataSource 協定方法
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        
        let imageView = UIImageView(image: images[indexPath.row])
        imageView.contentMode = .scaleAspectFill
        imageView.frame = cell.contentView.bounds  // 設置 imageView 的框架為 cell 的邊界
        cell.contentView.addSubview(imageView)
        
        return cell
    }

}
