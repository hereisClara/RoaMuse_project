import Foundation
import UIKit
import CoreML
import MapKit
import CoreLocation

class TestVC: UIViewController, CLLocationManagerDelegate {
    
    let button = UIButton()
    let textView = UITextView()
    let locationManager = CLLocationManager()
    
    // 定義關鍵詞與地點類型的映射
    let keywordCategoryMap: [String: [MKPointOfInterestCategory]] = [
        "海灘": [.beach],
        "森林": [.park],
        "山區": [.park],
        "河流": [.park],
        "湖泊": [.park],
        "高樓": [.park],
        "古蹟": [.museum],
        "橋梁": [.park], // 沒有 .bridge，使用 .park 作為替代
        "塔樓": [.park], // 沒有 .tower，使用 .park 作為替代
        "公園": [.park],
        "博物館": [.museum],
        "美術館": [.museum],
//        "購物中心": [.departmentStore, .store],
        "餐廳": [.restaurant],
        "咖啡廳": [.cafe],
        "學校": [.school],
        "醫院": [.hospital],
        "警察局": [.police],
        "郵局": [.postOffice],
        // 添加更多根據需要
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設置定位管理器
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        view.backgroundColor = .systemGray3
        setupUI()
    }
    
    func setupUI() {
        
        textView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 200)
        textView.backgroundColor = .white
        textView.font = UIFont.systemFont(ofSize: 18)
        view.addSubview(textView)
        
        button.setTitle("分析詩詞", for: .normal)
        button.frame = CGRect(x: (view.frame.width - 120) / 2, y: 320, width: 120, height: 50)
        button.addTarget(self, action: #selector(analyzeText), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        view.addSubview(button)
        
    }
    
    @objc func analyzeText() {
        let inputText = textView.text ?? ""
        
        // 確保有輸入文本
        guard !inputText.isEmpty else {
            print("請輸入文本")
            showAlert(title: "輸入錯誤", message: "請輸入文本以進行分析。")
            return
        }
        
        // 將文本按行分割（例如按句子、標點等）
        let textSegments = inputText.components(separatedBy: CharacterSet.newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // 載入模型
        guard let model = try? poemLocationNLP4(configuration: .init()) else {
            print("模型加載失敗")
            showAlert(title: "錯誤", message: "無法加載 NLP 模型。")
            return
        }
        
        var allResults = [String]()
        
        for segment in textSegments {
            // 使用模型進行預測
            do {
                let prediction = try model.prediction(text: segment)
                let landscape = prediction.label
                allResults.append(landscape)
            } catch {
                print("分析失敗：\(error.localizedDescription)")
            }
        }
        
        // 顯示所有結果
        showResult(landscapes: allResults)
    }

    func showResult(landscapes: [String]) {
        // 保留順序並移除重複項
        let uniqueLandscapes = Array(Set(landscapes))
        
        // 逐個進行地點搜尋
        searchPlaces(forKeywords: uniqueLandscapes)
    }

    func searchPlaces(forKeywords keywords: [String]) {
        guard let userLocation = locationManager.location?.coordinate else {
            print("無法取得使用者位置")
            showAlert(title: "定位錯誤", message: "無法取得您的位置，請檢查定位服務是否已啟用。")
            return
        }
        
        let dispatchGroup = DispatchGroup()
        var searchResults: [String] = []
        
        for keyword in keywords {
            dispatchGroup.enter()
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = keyword
            
            // 設置搜尋範圍
            let searchRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 5000, longitudinalMeters: 5000) // 調整為 5,000 米
            request.region = searchRegion
            
            // 設置地點類型過濾器
            if let categories = keywordCategoryMap[keyword], !categories.isEmpty {
                request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
            } else {
                // 如果沒有對應的類型，選擇不設置過濾器，以包括所有類別
                request.pointOfInterestFilter = nil
            }
            
            let search = MKLocalSearch(request: request)
            search.start { (response, error) in
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    print("搜尋失敗：\(error.localizedDescription)")
                    searchResults.append("關鍵詞: \(keyword)\n搜尋失敗: \(error.localizedDescription)")
                    return
                }
                
                if let mapItems = response?.mapItems, !mapItems.isEmpty {
                    var found = false
                    for item in mapItems {
                        if let name = item.name {
                            // 根據關鍵詞進行更精確的篩選
                            switch keyword {
                            case "森林":
                                if name.contains("森林") {
                                    let address = item.placemark.title ?? "無地址"
                                    let resultText = "關鍵詞: \(keyword)\n地點: 名稱: \(name), 地址: \(address)"
                                    searchResults.append(resultText)
                                    found = true
                                    break
                                }
                            case "海灘":
                                if name.contains("海灘") {
                                    let address = item.placemark.title ?? "無地址"
                                    let resultText = "關鍵詞: \(keyword)\n地點: 名稱: \(name), 地址: \(address)"
                                    searchResults.append(resultText)
                                    found = true
                                    break
                                }
                            case "高樓":
                                if item.pointOfInterestCategory == .park {
                                    let address = item.placemark.title ?? "無地址"
                                    let resultText = "關鍵詞: \(keyword)\n地點: 名稱: \(name), 地址: \(address)"
                                    searchResults.append(resultText)
                                    found = true
                                    break
                                }
                            // 根據需要添加更多關鍵詞的篩選條件
                            default:
                                // 對於其他關鍵詞，直接使用第一個結果
                                let address = item.placemark.title ?? "無地址"
                                let resultText = "關鍵詞: \(keyword)\n地點: 名稱: \(name), 地址: \(address)"
                                searchResults.append(resultText)
                                found = true
                                break
                            }
                        }
                        if found { break } // 找到符合條件的地點後退出循環
                    }
                    
                    if !found {
                        searchResults.append("關鍵詞: \(keyword)\n無找到符合的地點")
                    }
                } else {
                    searchResults.append("關鍵詞: \(keyword)\n無找到符合的地點")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let allResults = searchResults.joined(separator: "\n\n")
            self.showAlert(title: "搜尋結果", message: allResults)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // CLLocationManagerDelegate 方法
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 獲取最新位置
        if let location = locations.last {
            print("使用者位置：\(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失敗：\(error.localizedDescription)")
        showAlert(title: "定位錯誤", message: "無法取得您的位置，請檢查定位服務是否已啟用。")
    }
}
