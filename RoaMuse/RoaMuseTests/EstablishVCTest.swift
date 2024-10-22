//
//  EstablishVCTest.swift
//  RoaMuseTests
//
//  Created by 小妍寶 on 2024/10/22.
//

import XCTest
@testable import RoaMuse

final class EstablishVCTest: XCTestCase {
    var viewController: EstablishViewController!
    var slider: UISlider!
    var radiusLabel: UILabel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        viewController = EstablishViewController()
        viewController.loadViewIfNeeded()
        
        slider = UISlider()
        radiusLabel = UILabel()
        viewController.radiusLabel = radiusLabel
    }

    override func tearDownWithError() throws {
        viewController = nil
        slider = nil
        radiusLabel = nil
        
        try super.tearDownWithError()
    }

    func testSliderValueChanged() {
        // 設定滑桿的範圍
        slider.minimumValue = 1000
        slider.maximumValue = 15000
        
        // 設定 slider 的值
        slider.value = 1000
        
        // 模擬滑桿值的變化
        viewController.sliderValueChanged(slider)
        
        // 驗證 slider 的值是否被設為 1000
        XCTAssertEqual(slider.value, 1000, "Slider value should be rounded to 1000")
        
        // 驗證 label 的文字是否正確
        XCTAssertEqual(radiusLabel.text, "範圍半徑：1000 公尺", "Label text should display '範圍半徑：1000 公尺'")
    }
}
