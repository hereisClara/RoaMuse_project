import Foundation

// 定義簡化的 PlaceIdentifier 結構，保存地點的 id 和完成狀態

let userId = "Am5Jsa1tA0IpyXMLuilm"

struct Style {
    let name: String
    let introduction: String
}

let styles: [Style] = [
    Style(name: "奇險派", introduction: """
    以震盪光怪為美，以瘁索枯槁為美，以五彩斑斕為美。表現出重主觀心理、尚奇險怪異的創作傾向。
    他們的創作，表現的往往是自己心靈的歷程，他們常把現實生活中的感受，與自己虛構的世界融合在一起，
    其詩想像離奇怪誕，往往使人感到虛實不定，跳躍怪奇，不可確解。
    """),
    
    Style(name: "浪漫派", introduction: """
    以抒發個人情懷為中心，詠唱對自由人生個人價值的渴望與追求。詩詞自由、奔放、順暢、想像豐富、氣勢宏大。
    語言主張自然，反對雕刻。
    """),
    
    Style(name: "田園派", introduction: """
    閒適澹泊的思想情緒，色彩雅淡，意境幽深，能概括地描寫雄奇壯闊的景物，
    又能細緻入微地刻畫自然事物的動態；在自然景物的觀察上別有會心，
    能夠巧妙地捕捉適於表現其生活情趣的種種形象，構成獨到的意境。
    """)
]


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
