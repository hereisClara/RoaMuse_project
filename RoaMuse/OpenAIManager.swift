//
//  OpenAIManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/10/7.
//

import Foundation
import Alamofire

class OpenAIManager {
    
    static let shared = OpenAIManager()
    private let apiKey: String

    private init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let openAIKey = config["OPEN_AI_API_KEY"] as? String {
            self.apiKey = openAIKey
        } else {
            self.apiKey = ""  // 如果金鑰未設置，設置為空字符串（需要處理錯誤情況）
            print("openAIKey is missing!")
        }
    }

    func fetchSuggestion(poemLine: String, placeName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "https://api.openai.com/v1/chat/completions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let parameters: [String: Any] = [
            "model": "gpt-4", // 將模型切換為 GPT-4
                    "prompt": """
                    根據以下詩詞和地點名稱，生成一段最多 50 字的提示語，讓遊覽者感受到詩詞中的意境：

                    詩詞內容：『\(poemLine)』
                    地點名稱：\(placeName)
                    """,
                    "max_tokens": 70
            ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        if let json = value as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let text = choices.first?["text"] as? String {
                            completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
                        } else {
                            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "無法解析資料"])))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
    }
}

