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
    func formatDate(_ timestamp: Timestamp, format: String = "yyyy年MM月dd日 HH:mm") -> String {
        let date = timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    // 如果需要根據日期顯示不同的格式，可以添加其他方法
    func formatShortDate(_ timestamp: Timestamp) -> String {
        return formatDate(timestamp, format: "yyyy/MM/dd")
    }
}
