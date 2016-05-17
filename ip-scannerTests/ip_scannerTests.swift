//
//  ip_scannerTests.swift
//  ip-scannerTests
//
//  Created by Алексей Неронов on 10.05.16.
//  Copyright © 2016 Алексей Неронов. All rights reserved.
//

import XCTest
@testable import ip_scanner

class ip_scannerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let vc = ViewController()
        let size:CGRect = vc.size
        XCTAssertNotEqual(size.width, 0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    
}
