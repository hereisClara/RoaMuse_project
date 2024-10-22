//
//  HomeCollectionVCTests.swift
//  RoaMuseTests
//
//  Created by 小妍寶 on 2024/10/22.
//

import XCTest
@testable import RoaMuse

final class HomeCollectionVCTests: XCTestCase {
    
    var viewController: HomeCollectionViewController!
    var collectionView: MockCollectionView!
    var numberOfItems: Int!
    var poems: [Poem]!
    
    // 自訂的 Mock CollectionView 用於攔截插入行為
    class MockCollectionView: UICollectionView {
        var insertedIndexPaths: [IndexPath] = []
        
        override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
            updates?()
            completion?(true)
        }
        
        override func insertItems(at indexPaths: [IndexPath]) {
            insertedIndexPaths.append(contentsOf: indexPaths)
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        viewController = HomeCollectionViewController()
        viewController.loadViewIfNeeded()
        
        // 初始化 MockCollectionView
        let layout = UICollectionViewFlowLayout()
        collectionView = MockCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = viewController
        collectionView.delegate = viewController
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        // 初始化數據
        numberOfItems = 30
        poems = Array(repeating: Poem(id: "1", title: "Sample Title", poetry: "Sample Poetry", content: ["Sample Content"], tag: 1, season: nil, weather: nil, time: nil), count: 30)
        viewController.numberOfItems = numberOfItems
        viewController.poems = poems
    }
    
    override func tearDownWithError() throws {
        viewController = nil
        collectionView = nil
        numberOfItems = nil
        poems = nil
        
        try super.tearDownWithError()
    }
    
    func testWillDisplayCellInsertsNewItems() {
        // 檢查初始項目數量
        XCTAssertEqual(viewController.numberOfItems, 30, "初始的項目數量應為 30")
        
        // 模擬顯示第 25 個項目
        let indexPath = IndexPath(item: 25, section: 0)
        viewController.collectionView(collectionView, willDisplay: UICollectionViewCell(), forItemAt: indexPath)
        
        // 驗證插入新項目後，numberOfItems 是否增加
        XCTAssertEqual(viewController.numberOfItems, 45, "項目數量應增加 15")
        
        // 驗證 MockCollectionView 是否記錄了插入的項目
        XCTAssertEqual(collectionView.insertedIndexPaths.count, 15, "應插入 15 個新項目")
        XCTAssertEqual(collectionView.insertedIndexPaths.first, IndexPath(item: 30, section: 0), "插入的第一個項目應該是第 30 個")
        XCTAssertEqual(collectionView.insertedIndexPaths.last, IndexPath(item: 44, section: 0), "插入的最後一個項目應該是第 44 個")
    }
}
