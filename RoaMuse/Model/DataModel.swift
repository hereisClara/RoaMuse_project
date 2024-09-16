//
//  DataModel.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/13.
//

import Foundation

struct PlaceJson: Codable {
    let places: [Place]
}

// 定義 Place 結構
struct Place: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
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

// 定義 Trip 結構
struct Trip: Codable {
    let poem: Poem
    let id: String
    let places: [String]
    let tag: Int
    let season: Int
    let weather: Int
    let startTime: Int
    let isComplete: Bool
}

struct Json: Codable {
    let trips: [Trip]
}
