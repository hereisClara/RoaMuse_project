//
//  DateManager.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/20.
//

import Foundation
import FirebaseCore

class DateManager {
    
    static let shared = DateManager()
    
    private init() {}
    
    // 格式化日期
    func formatDate(_ date: Any, format: String = "yyyy年MM月dd日 HH:mm") -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            
            // 檢查傳入的是 Timestamp 還是 Date
            if let timestamp = date as? Timestamp {
                // 將 Timestamp 轉換為 Date
                return dateFormatter.string(from: timestamp.dateValue())
            } else if let date = date as? Date {
                // 如果是 Date，直接格式化
                return dateFormatter.string(from: date)
            } else {
                // 如果傳入的類型不是 Timestamp 或 Date，返回空字串
                return ""
            }
        }
    // 如果需要根據日期顯示不同的格式，可以添加其他方法
    func formatShortDate(_ timestamp: Timestamp) -> String {
        return formatDate(timestamp, format: "yyyy/MM/dd")
    }
}
