import Foundation
import FirebaseCore

// 定義簡化的 PlaceIdentifier 結構，保存地點的 id 和完成狀態

let notifyType = ["說你的貼文讚", "已回應貼文", "開始追蹤你"]

struct Style {
    let name: String
    let introduction: String
}

let season = ["不限", "春", "夏", "秋", "冬"]
let weather = ["不限", "晴天", "雨天"]
let time = ["不限", "白天", "傍晚", "晚上"]

let styles: [Style] = [
    Style(name: "奇險派", introduction: """
    以震盪光怪為美，以瘁索枯槁為美，以五彩斑斕為美。把現實生活的感受，與虛構的世界融合，離奇怪誕，虛實不定。
    """),
    
    Style(name: "浪漫派", introduction: """
    以抒發個人情懷為中心，詠唱對自由人生個人價值的渴望與追求。詩詞自由、奔放、順暢、想像豐富、氣勢宏大。
    """),
    
    Style(name: "田園派", introduction: """
    閒適澹泊的思想情緒，色彩雅淡，意境幽深，能概括地描寫雄奇壯闊的景物，又能細緻入微地刻畫自然事物的動態。
    """)
]

// 定義 Poem 結構
struct Poem: Codable {
    var id: String = ""
    let title: String
    let poetry: String
    let content: [String]
    let tag: Int
    let season: Int?
    let weather: Int?
    let time: Int?
}

// TODO: 更新資料結構 還有homeVC跟articleTripVC的keyword傳值

struct Trip: Codable {
    let poemId: String
    let id: String
    let placeIds: [String]
    let keywordPlaceIds: [[String: String]]?
    let tag: Int
    let season: Int?      // 修改为 Int?
    let weather: Int?     // 修改为 Int?
    let startTime: Date?  // 保持为 Date?
}


// 定義 Place 結構，存放地點詳細資料
struct Place: Codable, Hashable {
    var id: String
    let name: String
    let latitude: Double
    let longitude: Double
}

struct Json: Codable {
    let trips: [Trip]
}

struct User: Codable {
    var userId: String                // 用戶ID
    var userName: String              // 用戶名稱
    var email: String                 // 用戶郵箱
    var bookmarkPost: [String]        // 收藏的文章IDs
    var bookmarkTrip: [String]        // 收藏的行程IDs
    var completedTrip: [String]       // 已完成的行程IDs
    var completedPlace: [CompletedPlace] // 已完成的地點資料 (依據行程)

    // 新增完成的行程
    mutating func completeTrip(tripId: String) {
        if !completedTrip.contains(tripId) {
            completedTrip.append(tripId)
        }
    }

    // 新增行程中已完成的地點
    mutating func completePlace(in tripId: String, placeId: String) {
        // 檢查是否已經有該行程的記錄
        if let index = completedPlace.firstIndex(where: { $0.tripId == tripId }) {
            if !completedPlace[index].placeIds.contains(placeId) {
                completedPlace[index].placeIds.append(placeId)
            }
        } else {
            // 如果尚無該行程的記錄，新增一筆
            completedPlace.append(CompletedPlace(tripId: tripId, placeIds: [placeId]))
        }
    }
}

struct CompletedPlace: Codable {
    let tripId: String                // 行程ID
    var placeIds: [String]            // 行程中完成的地點IDs
}

struct PlaceTripInfo: Codable {
    let placeId: String
    var tripIds: [String]
}

struct TaskSet {
    var totalTasks: Int
    var completedTasks: Int
}

struct PlacePoemPair {
    let placeId: String
    let poemLine: String
}

struct Chat {
    let userName: String
    let lastMessage: String
    let profileImage: String 
}


// 聊天訊息模型
struct ChatMessage {
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: Date
}

struct Notification: Codable {
    var to: String
    var from: String
    var postId: String? // postId 是可選的
    var type: Int
    var subType: String? // 類型的細分 (可選)
    var title: String? // 通知的標題
    var message: String? // 通知的具體內容
    var actionUrl: String? // 點擊後跳轉的URL
    var createdAt: Date
    var isRead: Int = 0 // 默認為未讀
    var status: String = "pending" // 默認狀態為 pending
    var priority: Int = 0 // 默認優先級為普通
    var id: String? // Firestore 自動生成的 ID
}

extension Notification {
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "to": to,
            "from": from,
            "type": type,
            "createdAt": Timestamp(date: createdAt), // 将 Date 转换为 Timestamp
            "isRead": isRead,
            "status": status,
            "priority": priority
        ]
        
        if let postId = postId {
            dict["postId"] = postId
        }
        if let subType = subType {
            dict["subType"] = subType
        }
        if let title = title {
            dict["title"] = title
        }
        if let message = message {
            dict["message"] = message
        }
        if let actionUrl = actionUrl {
            dict["actionUrl"] = actionUrl
        }
        if let id = id {
            dict["id"] = id
        }
        return dict
    }
}

let cityCodeMapping: [String: String] = [
    "CHA": "彰化縣",
    "CYQ": "嘉義縣",
    "HSQ": "新竹縣",
    "HUA": "花蓮縣",
    "ILA": "宜蘭縣",
    "KIN": "金門縣",
    "LIE": "連江縣",
    "MIA": "苗栗縣",
    "NAN": "南投縣",
    "PEN": "澎湖縣",
    "PIF": "屏東縣",
    "TTT": "臺東縣",
    "YUN": "雲林縣",
    "CYI": "嘉義市",
    "HSZ": "新竹市",
    "KEE": "基隆市",
    "KHH": "高雄市",
    "NWT": "新北市",
    "TAO": "桃園市",
    "TNN": "臺南市",
    "TPE": "臺北市",
    "TXG": "臺中市"
]
