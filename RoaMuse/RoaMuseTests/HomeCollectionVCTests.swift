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
        
        let layout = UICollectionViewFlowLayout()
        collectionView = MockCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = viewController
        collectionView.delegate = viewController
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
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
        
        XCTAssertEqual(viewController.numberOfItems, 30, "初始的項目數量應為 30")
        
        let indexPath = IndexPath(item: 25, section: 0)
        viewController.collectionView(collectionView, willDisplay: UICollectionViewCell(), forItemAt: indexPath)
        
        XCTAssertEqual(viewController.numberOfItems, 45, "項目數量應增加 15")
        
        XCTAssertEqual(collectionView.insertedIndexPaths.count, 15, "應插入 15 個新項目")
        XCTAssertEqual(collectionView.insertedIndexPaths.first, IndexPath(item: 30, section: 0), "插入的第一個項目應該是第 30 個")
        XCTAssertEqual(collectionView.insertedIndexPaths.last, IndexPath(item: 44, section: 0), "插入的最後一個項目應該是第 44 個")
    }
}
