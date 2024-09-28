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
    
    var mapView: MKMapView!
    var images: [UIImage] = []  // 定義存放照片的屬性
    var userId: String? {
        return UserDefaults.standard.string(forKey: "userId")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        view.addSubview(mapView)
        
        // 設置 clustering
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Marker")
        
        // 加載用戶的 completedPlace 並添加標註點
        loadCompletedPlacesAndAddAnnotations()
    }
    
    // 從 Firestore 加載使用者的 completedPlace 資料，並根據 placeId 查詢 place 資訊
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
            
            // 抓取 placeId 並去重
            var uniquePlaceIds = Set<String>()
            for placeEntry in completedPlace {
                if let placeIds = placeEntry["placeIds"] as? [String] {
                    uniquePlaceIds.formUnion(placeIds)
                }
            }
            
            // 根據 placeId 從 places 集合中抓取對應的座標
            self.fetchPlaces(for: Array(uniquePlaceIds))
        }
    }
    
    // 根據 placeId 查詢 places 資訊，並添加標註點
    func fetchPlaces(for placeIds: [String]) {
        let placesRef = Firestore.firestore().collection("places")
        let dispatchGroup = DispatchGroup()
        
        for placeId in placeIds {
            dispatchGroup.enter()
            
            placesRef.document(placeId).getDocument { documentSnapshot, error in
                if let error = error {
                    print("獲取 place 失敗: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                
                guard let document = documentSnapshot, let data = document.data(),
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let placeName = data["name"] as? String else {
                    print("錯誤: 無法解析 place 資料")
                    dispatchGroup.leave()
                    return
                }
                
                // 添加標註點
                let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = placeName
                self.mapView.addAnnotation(annotation)
                print("成功添加標註點: \(placeName) at (\(latitude), \(longitude))")
                
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
        if annotation is MKClusterAnnotation {
            // 如果是 cluster，使用內建的 cluster view
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: annotation)
            return annotationView
        }
        
        // 其他標註點設置
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Marker", for: annotation)
        annotationView.clusteringIdentifier = "clusterID"
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            // 假設 annotation 附帶了一個屬性可以讓我們取得對應的 tripId
            if let tripId = getTripId(from: annotation) {
                // 查詢並顯示詩的資訊
                fetchTripAndPoemData(for: tripId) { poemTitle, poemAuthor in
                    DispatchQueue.main.async {
                        self.showPoemAlert(title: poemTitle, author: poemAuthor)
                    }
                }
            } else {
                print("無法找到對應的 tripId")
            }
        }
    }

    // 方法根據標註點 (annotation) 獲取對應的 tripId (具體邏輯依你的資料結構)
    func getTripId(from annotation: MKAnnotation) -> String? {
        // 這裡假設 annotation 有某種屬性存儲 tripId，根據實際情況來取值
//         例如：annotation.subtitle = tripId
        return annotation.subtitle ?? nil
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
