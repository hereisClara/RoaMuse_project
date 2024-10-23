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
        
        slider.minimumValue = 1000
        slider.maximumValue = 15000
        
        slider.value = 1000
        
        viewController.sliderValueChanged(slider)
        
        XCTAssertEqual(slider.value, 1000, "Slider value should be rounded to 1000")
        
        XCTAssertEqual(radiusLabel.text, "範圍半徑：1000 公尺", "Label text should display '範圍半徑：1000 公尺'")
    }
    
    func testSliderStepIs1000() {
        viewController.radiusSlider.minimumValue = 1000
        viewController.radiusSlider.maximumValue = 15000
        
        viewController.radiusSlider.value = 1000
        viewController.sliderValueChanged(viewController.radiusSlider)
        
        let stepValue: Float = 1000
        let originalValue = viewController.radiusSlider.value
        
        viewController.radiusSlider.value += stepValue
        viewController.sliderValueChanged(viewController.radiusSlider)
        
        XCTAssertEqual(viewController.radiusSlider.value, originalValue + stepValue, "Slider value should have increased by 1000")
        
        viewController.radiusSlider.value -= stepValue
        viewController.sliderValueChanged(viewController.radiusSlider)
        
        XCTAssertEqual(viewController.radiusSlider.value, originalValue, "Slider value should have returned to the original value")
    }
}
