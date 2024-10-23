import Foundation
import FirebaseCore

let notifyType = ["說你的貼文讚", "已回應貼文", "開始追蹤你"]

struct Style {
    let name: String
    let introduction: String
}

let season = ["不限", "春", "夏", "秋", "冬"]
let weather = ["不限", "晴天", "雨天"]
let time = ["不限", "白天", "傍晚", "晚上"]

let styles: [Style] = [
    Style(name: "隨機", introduction: """
    穿越千年，與詩的一期一會。
    """),
    
    Style(name: "奇險派", introduction: """
    以震盪光怪為美，以瘁索枯槁為美，以五彩斑斕為美。融合現實與虛構，離奇怪誕。
    """),
    
    Style(name: "浪漫派", introduction: """
    以抒發個人情懷為中心，詠唱對自由人生個人價值的渴望與追求。
    """),
    
    Style(name: "田園派", introduction: """
    閒適澹泊的思想情緒，色彩雅淡，意境幽深。
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

struct Trip: Codable {
    let poemId: String
    let id: String
    let placeIds: [String]
    let keywordPlaceIds: [[String: String]]?
    let tag: Int
    let season: Int?
    let weather: Int?
    let startTime: Date?
}

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
    var userId: String
    var userName: String
    var email: String
    var bookmarkPost: [String]
    var bookmarkTrip: [String]
    var completedTrip: [String]
    var completedPlace: [CompletedPlace]

    mutating func completeTrip(tripId: String) {
        if !completedTrip.contains(tripId) {
            completedTrip.append(tripId)
        }
    }

    mutating func completePlace(in tripId: String, placeId: String) {
        if let index = completedPlace.firstIndex(where: { $0.tripId == tripId }) {
            if !completedPlace[index].placeIds.contains(placeId) {
                completedPlace[index].placeIds.append(placeId)
            }
        } else {
            completedPlace.append(CompletedPlace(tripId: tripId, placeIds: [placeId]))
        }
    }
}

struct CompletedPlace: Codable {
    let tripId: String
    var placeIds: [String]
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
    var postId: String?
    var type: Int
    var subType: String?
    var title: String?
    var message: String?
    var actionUrl: String?
    var createdAt: Date
    var isRead: Int = 0
    var status: String = "pending"
    var priority: Int = 0
    var id: String?
}

extension Notification {
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "to": to,
            "from": from,
            "type": type,
            "createdAt": Timestamp(date: createdAt),
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
