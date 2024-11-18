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
    
    func formatDate(_ date: Any, format: String = "yyyy年MM月dd日 HH:mm") -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            
            if let timestamp = date as? Timestamp {
                return dateFormatter.string(from: timestamp.dateValue())
            } else if let date = date as? Date {
                return dateFormatter.string(from: date)
            } else {
                return ""
            }
        }
    
    func formatShortDate(_ timestamp: Timestamp) -> String {
        return formatDate(timestamp, format: "yyyy/MM/dd")
    }
}
