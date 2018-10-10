//
//  RegularExpressionTests.swift
//  RegularExpressionTests
//
//  Created by Matt Brandt on 10/10/18.
//  Copyright © 2018 Walkingdog. All rights reserved.
//

import XCTest
@testable import NetMonitor

class RegularExpressionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRegEx() {
        let RE = RegularExpression(pattern: "([0-9]+)")
        let testString = "testing 10110"

        XCTAssert(RE.matchesWithString(testString))
        XCTAssert(RE.prefix == "testing ")
        XCTAssert(RE.match(1) == "10110")
        XCTAssert(RE.match(2) == nil)
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
