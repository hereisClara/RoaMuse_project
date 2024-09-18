//
//  TestFile.swift
//  RoaMuse
//
//  Created by 小妍寶 on 2024/9/18.
//

import Foundation
import UIKit
import FirebaseFirestore


class ViewController: UIViewController {

    let db = Firestore.firestore() // 初始化 Firestore

    override func viewDidLoad() {
        super.viewDidLoad()

        // 準備要上傳的資料
        let db = Firestore.firestore()
        let tripData: [String: Any] = [
            "poem": [
                "title": "〈感諷五首．其三〉",
                "poetry": "李賀",
                "original": [
                    "南山何其悲，鬼雨灑空草！",
                    "長安夜半秋，風前幾人老？",
                    "低迷黃昏徑，裊裊青櫟道；",
                    "月午樹無影，一山唯白曉，",
                    "漆炬迎新人，幽壙螢擾擾。"
                ],
                "translation": [
                    "南山是多麼的悲涼，鬼雨灑落在空曠的草地上。",
                    "長安的深夜已是秋天，在風中不知多少人已經變老。",
                    "黃昏的路徑彷彿籠罩著一層迷霧，青櫟樹的道路上飄著悠長的微風。",
                    "夜半的月亮高懸，樹木卻無影，整座山上只有白色的晨曦。",
                    "漆黑的火炬迎接著新來的人，幽暗的墓穴中螢火蟲在四處飛舞。"
                ],
                "secretTexts": [
                    "李賀經常騎著一匹瘦馬，帶著小童子邊走邊思索，一旦有了好句子或是來了靈感，便把所想到的靈感急速記錄下來，投進小童子背著的小錦囊裡。",
                    "李賀的詩想像力豐富，意境詭異華麗，常用些險韻奇字。",
                    "李賀只活了短短二十七歲。他經歷了安史之亂帶來的巨大衝擊。"
                ],
                "situationText": [
                    "當細雨輕灑於廣袤的草地上，水霧繚繞，彷彿鬼雨隨風飄落，帶來一種淒美的氛圍。",
                    "夕陽西下，餘暉灑在蜿蜒的山徑間，步道旁的樹木枝葉隨風輕搖。"
                ]
            ],
            "id": "trip01",
            "places": [
                ["id": "001", "isComplete": false],
                ["id": "002", "isComplete": false],
                ["id": "003", "isComplete": false]
            ],
            "tag": 0,
            "season": 2,
            "weather": 1,
            "startTime": 1,
            "isComplete": false
        ]

        // 將資料寫入 Firestore
        db.collection("trips").addDocument(data: tripData) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added successfully!")
            }
        }
    }
}

