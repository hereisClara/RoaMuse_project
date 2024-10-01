//import Foundation
//import UIKit
//import CoreML
//import MapKit
//import CoreLocation
//import FirebaseFirestore
//
//class TestVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
//    
//    
//    
//    let button = UIButton()
//    let randomButton = UIButton()
//    let textView = UITextView()
//    let locationManager = CLLocationManager()
//    let mapView = MKMapView()
//    
//    var foundLocations: [CLLocationCoordinate2D] = []
//    var allRouteSteps: [String] = []
//    var poemsFromFirebase: [[String: Any]] = []
//    
//    let keywordCategoryMap: [String: [MKPointOfInterestCategory]] = [
//        "海灘": [.beach, .park],
//        "森林": [.park],
//        "山區": [.park],
//        "河流": [.park],
//        "湖泊": [.park],
//        "高樓": [.park],
//    ]
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        fetchPoetDataFromFirebase()
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//        view.backgroundColor = .systemGray3
//        setupUI()
////        uploadPoetDataToFirebase()
//    }
//    
//    func setupUI() {
//        // 設置 textView
//        textView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 100)
//        textView.backgroundColor = .white
//        textView.font = UIFont.systemFont(ofSize: 18)
//        textView.layer.cornerRadius = 8
//        view.addSubview(textView)
//        
//        // 設置 button
//        button.setTitle("分析詩詞", for: .normal)
//        button.frame = CGRect(x: (view.frame.width - 120) / 2, y: 220, width: 120, height: 50)
//        button.addTarget(self, action: #selector(analyzeText), for: .touchUpInside)
//        button.backgroundColor = .systemBlue
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 10
//        view.addSubview(button)
//        
//        randomButton.setTitle("隨機選擇詩詞", for: .normal)
//                randomButton.frame = CGRect(x: (view.frame.width - 180) / 2, y: 300, width: 180, height: 50)
//                randomButton.addTarget(self, action: #selector(selectRandomPoem), for: .touchUpInside)
//                randomButton.backgroundColor = .systemGreen
//                randomButton.setTitleColor(.white, for: .normal)
//                randomButton.layer.cornerRadius = 10
//                view.addSubview(randomButton)
//        
//        // 設置 mapView
//        mapView.frame = CGRect(x: 20, y: 450, width: view.frame.width - 40, height: 200)
//        mapView.delegate = self
//        view.addSubview(mapView)
//    }
//    
//    @objc func analyzeText() {
//        let inputText = textView.text ?? ""
//        guard !inputText.isEmpty else {
//            showAlert(title: "輸入錯誤", message: "請輸入文本以進行分析。")
//            return
//        }
//        let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
//        guard let model = try? poemLocationNLP3(configuration: .init()) else {
//            showAlert(title: "錯誤", message: "無法加載 NLP 模型。")
//            return
//        }
//        var allResults = [String]()
//        for segment in textSegments {
//            do {
//                let prediction = try model.prediction(text: segment)
//                let landscape = prediction.label
//                allResults.append(landscape)
//            } catch {
//                print("分析失敗：\(error.localizedDescription)")
//            }
//        }
//        showResult(landscapes: allResults)
//    }
//    
//    @objc func selectRandomPoem() {
//            guard !poemsFromFirebase.isEmpty else {
//                showAlert(title: "錯誤", message: "尚未從 Firebase 中獲取到任何詩詞。")
//                return
//            }
//            
//            // 隨機選擇一首詩
//            let randomPoet = poemsFromFirebase.randomElement()!
//            let poetName = randomPoet["name"] as? String
//            let poems = randomPoet["poems"] as? [[String: Any]]
//            let randomPoem = poems?.randomElement()!
//            let poemTitle = randomPoem?["title"] as? String
//            let poemContent = (randomPoem?["content"] as? [String])?.joined(separator: "\n")
//            
//            let alertMessage = "詩人: \(poetName)\n詩名: \(poemTitle)\n詩文:\n\(poemContent)"
//            showAlert(title: "隨機選擇的詩", message: alertMessage)
//            
//            // 分析詩詞
//        processPoemText(poemContent ?? "")
//        }
//        
//        func processPoemText(_ inputText: String) {
//            let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
//            guard let model = try? poemLocationNLP3(configuration: .init()) else {
//                showAlert(title: "錯誤", message: "無法加載 NLP 模型。")
//                return
//            }
//            var allResults = [String]()
//            for segment in textSegments {
//                do {
//                    let prediction = try model.prediction(text: segment)
//                    let landscape = prediction.label
//                    allResults.append(landscape)
//                } catch {
//                    print("分析失敗：\(error.localizedDescription)")
//                }
//            }
//            showResult(landscapes: allResults)
//        }
//        
//        func fetchPoetDataFromFirebase() {
//            let db = Firestore.firestore()
//            db.collection("poets").getDocuments { (snapshot, error) in
//                if let error = error {
//                    print("從 Firebase 獲取數據失敗：\(error.localizedDescription)")
//                } else if let snapshot = snapshot {
//                    self.poemsFromFirebase = snapshot.documents.map { $0.data() }
//                    print("成功從 Firebase 獲取數據")
//                }
//            }
//        }
//        
//        func showResult(landscapes: [String]) {
//            let uniqueLandscapes = Array(Set(landscapes))
//            searchPlacesSequentially(forKeywords: uniqueLandscapes)
//        }
//    
//    func searchPlacesSequentially(forKeywords keywords: [String]) {
//        guard let userLocation = locationManager.location?.coordinate else {
//            showAlert(title: "定位錯誤", message: "無法取得您的位置，請檢查定位服務是否已啟用。")
//            return
//        }
//        var currentLocation = userLocation
//        foundLocations = []
//        allRouteSteps = []
//        mapView.removeAnnotations(mapView.annotations)
//        mapView.removeOverlays(mapView.overlays)
//        let dispatchGroup = DispatchGroup()
//        
//        func searchNextKeyword(index: Int) {
//            if index >= keywords.count {
//                dispatchGroup.notify(queue: .main) {
//                    self.plotRoutes() // 將交通細節打印到 log 中
//                }
//                return
//            }
//            
//            let keyword = keywords[index]
//            let request = MKLocalSearch.Request()
//            request.naturalLanguageQuery = keyword
//            let searchRegion = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 5000, longitudinalMeters: 5000)
//            request.region = searchRegion
//            if let categories = keywordCategoryMap[keyword], !categories.isEmpty {
//                request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
//            } else {
//                request.pointOfInterestFilter = nil
//            }
//            let search = MKLocalSearch(request: request)
//            
//            dispatchGroup.enter()
//            search.start { (response, error) in
//                defer { dispatchGroup.leave() }
//                if let error = error {
//                    print("搜尋失敗：\(error.localizedDescription)")
//                    self.addAnnotation(for: keyword, name: nil, address: nil, coordinate: nil)
//                    searchNextKeyword(index: index + 1)
//                    return
//                }
//                
//                if let mapItems = response?.mapItems {
//                    let filteredItems = mapItems.filter { item in
//                        let name = item.name?.lowercased() ?? ""
//                        return !name.contains("restaurant") && !name.contains("café") && !name.contains("coffee")
//                    }
//                    
//                    if let closestItem = filteredItems.first {
//                        let name = closestItem.name ?? "無名稱"
//                        let address = closestItem.placemark.title ?? "無地址"
//                        self.addAnnotation(for: keyword, name: name, address: address, coordinate: closestItem.placemark.coordinate)
//                        self.foundLocations.append(closestItem.placemark.coordinate)
//                        currentLocation = closestItem.placemark.coordinate
//                        print("地景關鍵詞: \(keyword), 地點名稱: \(name), 地址: \(address ?? "無地址")")
//                        let alertMessage = "地點名稱: \(name)\n地景關鍵詞: \(keyword)"
//                        self.showAlert(title: "地點與地景分析", message: alertMessage)
//                    } else {
//                        self.addAnnotation(for: keyword, name: nil, address: nil, coordinate: nil)
//                    }
//                }
//                searchNextKeyword(index: index + 1)
//            }
//        }
//        
//        searchNextKeyword(index: 0)
//    }
//    
//    func addAnnotation(for keyword: String, name: String?, address: String?, coordinate: CLLocationCoordinate2D?) {
//        let annotation = MKPointAnnotation()
//        annotation.title = name ?? "無名稱"
//        annotation.subtitle = address ?? "無地址"
//        if let coord = coordinate {
//            annotation.coordinate = coord
//        } else {
//            annotation.coordinate = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
//        }
//        mapView.addAnnotation(annotation)
//    }
//    
//    func plotRoutes() {
//        guard foundLocations.count > 1 else {
//            showAlert(title: "路線規劃", message: "找到的地點不足以規劃路線。")
//            return
//        }
//
//        let dispatchGroup = DispatchGroup()
//        allRouteSteps = []
//
//        for num in 0..<(foundLocations.count - 1) {
//            let source = foundLocations[num]
//            let destination = foundLocations[num + 1]
//            let request = MKDirections.Request()
//            let sourcePlacemark = MKPlacemark(coordinate: source)
//            let destinationPlacemark = MKPlacemark(coordinate: destination)
//            request.source = MKMapItem(placemark: sourcePlacemark)
//            request.destination = MKMapItem(placemark: destinationPlacemark)
//            request.transportType = .automobile
//
//            let directions = MKDirections(request: request)
//            dispatchGroup.enter()
//            directions.calculate { (response, error) in
//                defer { dispatchGroup.leave() }
//                if let error = error {
//                    print("路線規劃失敗：\(error.localizedDescription)")
//                    return
//                }
//                if let route = response?.routes.first {
//                    self.mapView.addOverlay(route.polyline)
//
//                    // 使用反向地理編碼獲取地名
//                    self.getLocationName(coordinate: source) { sourceName in
//                        self.getLocationName(coordinate: destination) { destinationName in
//                            // 將交通細節打印到控制台
//                            print("從 \(sourceName) 到 \(destinationName)")
//                            for step in route.steps {
//                                print(step.instructions)
//                            }
//                            
//                            // 可選：將結果顯示在 UI 或 Alert 中
//                        }
//                    }
//
//                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 100, left: 20, bottom: 100, right: 20), animated: true)
//                }
//            }
//        }
//
//        dispatchGroup.notify(queue: .main) {
//            print("路線規劃完成")
//        }
//    }
//
//    func getLocationName(coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
//        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//        let geocoder = CLGeocoder()
//
//        geocoder.reverseGeocodeLocation(location) { placemarks, error in
//            if let error = error {
//                print("反向地理編碼失敗: \(error.localizedDescription)")
//                completion("未知地點")
//                return
//            }
//
//            if let placemark = placemarks?.first {
//                // 優先顯示地區名稱(locality)，如果無法獲取，則顯示完整地址(name)
////                if let locality = placemark.locality {
////                    completion(locality)
////                } else 
//                if let name = placemark.name {
//                    completion(name)
//                } else {
//                    completion("未知地點")
//                }
////            } else {
////                completion("未知地點")
//            }
//        }
//    }
//
//    
//    func showRouteSteps() {
//        let stepsText = allRouteSteps.joined(separator: "\n")
//        showAlert(title: "路線步驟", message: stepsText)
//    }
//    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        if let polyline = overlay as? MKPolyline {
//            let renderer = MKPolylineRenderer(overlay: polyline)
//            renderer.strokeColor = .systemBlue
//            renderer.lineWidth = 4
//            return renderer
//        }
//        return MKOverlayRenderer(overlay: overlay)
//    }
//    
//    func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "確定", style: .default, handler: nil)
//        alert.addAction(okAction)
//        self.present(alert, animated: true, completion: nil)
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.last {
//            mapView.setRegion(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        showAlert(title: "定位錯誤", message: "無法取得您的位置，請檢查定位服務是否已啟用。")
//    }
//}
//
//extension TestVC: UITextViewDelegate {
//    func textViewDidChange(_ textView: UITextView) {
//        // 您可以在這裡添加即時文本分析的功能（如果需要）
//    }
//    
//    func uploadPoetDataToFirebase() {
//        // 初始化 Firestore
//        let db = Firestore.firestore()
//        
//        let poems: [Poem] = [
//            // 李白的詩
//            Poem(id: "", title: "送孟浩然之廣陵", poetry: "李白", content: [
//                "故人西辭黃鶴樓，煙花三月下揚州。",
//                "孤帆遠影碧空盡，唯見長江天際流。"
//            ], tag: 1),
//            Poem(id: "", title: "早發白帝城", poetry: "李白", content: [
//                "朝辭白帝彩雲間，千里江陵一日還。",
//                "兩岸猿聲啼不住，輕舟已過萬重山。"
//            ], tag: 1),
//            Poem(id: "", title: "獨坐敬亭山", poetry: "李白", content: [
//                "眾鳥高飛盡，孤雲獨去閒。",
//                "相看兩不厭，只有敬亭山。"
//            ], tag: 1),
//            Poem(id: "", title: "送友人", poetry: "李白", content: [
//                "青山橫北郭，白水繞東城。",
//                "此地一為別，孤蓬萬里征。",
//                "浮雲遊子意，落日故人情。",
//                "揮手自茲去，蕭蕭班馬鳴。"
//            ], tag: 1),
//            Poem(id: "", title: "望天門山", poetry: "李白", content: [
//                "天門中斷楚江開，碧水東流至此回。",
//                "兩岸青山相對出，孤帆一片日邊來。"
//            ], tag: 1),
//            
//            // 王維的詩
//            Poem(id: "", title: "山居秋暝", poetry: "王維", content: [
//                "空山新雨後，天氣晚來秋。",
//                "明月松間照，清泉石上流。",
//                "竹喧歸浣女，蓮動下漁舟。",
//                "隨意春芳歇，王孫自可留。"
//            ], tag: 2),
//            Poem(id: "", title: "山中", poetry: "王維", content: [
//                "荊溪白石出，天寒紅葉稀。",
//                "山路元無雨，空翠濕人衣。"
//            ], tag: 2),
//            Poem(id: "", title: "鹿柴", poetry: "王維", content: [
//                "空山不見人，但聞人語響。",
//                "返景入深林，復照青苔上。"
//            ], tag: 2),
//            Poem(id: "", title: "送別", poetry: "王維", content: [
//                "下馬飲君酒，問君何所之？",
//                "君言不得意，歸臥南山陲。",
//                "但去莫復問，白雲無盡時。"
//            ], tag: 2),
//            Poem(id: "", title: "答裴迪輞口遇雨憶終南山之作", poetry: "王維", content: [
//                "淼淼寒流廣，蒼蒼秋雨晦。",
//                "君問終南山，心知白雲外。"
//            ], tag: 2),
//            
//            // 韓愈的詩
//            Poem(id: "", title: "早春呈水部張十八員外 / 初春小雨", poetry: "韓愈", content: [
//                "天街小雨潤如酥，草色遙看近卻無。",
//                "最是一年春好處，絕勝煙柳滿皇都。"
//            ], tag: 0),
//            Poem(id: "", title: "晚春二首·其二", poetry: "韓愈", content: [
//                "誰收春色將歸去，慢綠妖紅半不存。",
//                "榆莢只能隨柳絮，等閒撩亂走空園。"
//            ], tag: 0),
//            
//            // 賈島的詩
//            Poem(id: "", title: "尋隱者不遇", poetry: "賈島", content: [
//                "松下問童子，言師採藥去。",
//                "只在此山中，雲深不知處。"
//            ], tag: 0),
//            Poem(id: "", title: "絕句", poetry: "賈島", content: [
//                "海底有明月，圓於天上輪。",
//                "得之一寸光，可買千里春。"
//            ], tag: 0),
//            
//            // 李賀的詩
//            Poem(id: "", title: "蜀國弦", poetry: "李賀", content: [
//                "楓香晚花靜，錦水南山影。",
//                "驚石墜猿哀，竹雲愁半嶺。",
//                "涼月生秋浦，玉沙粼粼光。",
//                "誰家紅淚客，不忍過瞿塘。"
//            ], tag: 0)
//        ]
//        
//        // 準備上傳數據
//        for var poem in poems {
//            var poemData: [String: Any] = [
//                "title": poem.title,
//                "poetry": poem.poetry,  // 詩人的名字
//                "content": poem.content,
//                "tag": poem.tag
//            ]
//            
//            // 上傳詩詞，並讓 Firestore 自動生成 documentID
//            let docRef = db.collection("poems").addDocument(data: poemData) { error in
//                if let error = error {
//                    print("上傳失敗: \(error.localizedDescription)")
//                } else {
//                    print("詩詞上傳成功: \(poem.title)")
//                }
//            }
//            
//            // 獲取 Firestore 自動生成的 documentID 並更新 `poem.id`
//            docRef.updateData(["id": docRef.documentID]) { error in
//                if let error = error {
//                    print("更新 ID 失敗: \(error.localizedDescription)")
//                } else {
//                    poem.id = docRef.documentID
//                    print("成功更新詩詞 \(poem.title) 的 ID: \(poem.id)")
//                }
//            }
//        }
//    }
//}
//
