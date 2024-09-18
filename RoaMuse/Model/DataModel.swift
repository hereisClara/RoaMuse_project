import Foundation

// 定義簡化的 PlaceIdentifier 結構，保存地點的 id 和完成狀態
struct PlaceId: Codable {
    let id: String
    let isComplete: Bool
}

// 定義 Poem 結構
struct Poem: Codable {
    let title: String
    let poetry: String
    let original: [String]
    let translation: [String]
    let secretTexts: [String]
    let situationText: [String]
}

// 定義 Trip 結構，保存地點 id 和完成狀態
struct Trip: Codable {
    let poem: Poem
    let id: String
    let places: [PlaceId]  // 保存地點的 id 和完成狀態
    let tag: Int
    let season: Int
    let weather: Int
    let startTime: Int
    let isComplete: Bool
}

// 定義 Place 結構，存放地點詳細資料
struct Place: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
}

struct Json: Codable {
    let trips: [Trip]
}
