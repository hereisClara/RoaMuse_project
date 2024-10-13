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
            "model": "gpt-4", // 使用更新的模型
            "temperature": 0.7, // 控制內容的多樣性
            "messages": [
                ["role": "system", "content": """
                你是一位創造詩句意境提示的助手。根據詩句和地點產生一段50到60字的描述，讓遊覽者感受詩句的意境，並以句號結束。
                """],
                ["role": "user", "content": """
                根據以下詩詞和地點名稱，生成一段50到60字的情境提示語，讓遊覽者感受到詩詞中的意境，並確保句子斷句清楚，以句號結束：

                詩詞內容：『\(poemLine)』
                地點名稱：\(placeName)
                """]
            ],
            "max_tokens": 120
        ]

        // 發送 API 請求
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    print("API Response: \(value)")
                    if let json = value as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let text = message["content"] as? String {
                        
                        // 裁剪內容至最後一個句號
                        let trimmedText = self.trimToLastSentenceEnd(text)
                        completion(.success(trimmedText))
                    } else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "無法解析資料"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    // 將文字裁剪至最後一個句號
    func trimToLastSentenceEnd(_ text: String) -> String {
        if let lastPeriodRange = text.range(of: "。", options: .backwards) {
            let trimmedText = String(text[..<lastPeriodRange.upperBound])
            return trimmedText
        }
        return text // 如果沒有句號，返回原文字
    }

}

