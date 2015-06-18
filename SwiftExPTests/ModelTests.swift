//
//  ModelTests.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 18.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

import XCTest
import SwiftExP

private func assertDescription(expression: Expression, _ description: String) {
    XCTAssertEqual(String(expression), description)
}

class ModelTests: XCTestCase {
    
    func testString() {
        assertDescription(.StringAtom("a"),    "\"a\"")
        assertDescription(.StringAtom("a b"),  "\"a b\"")
        assertDescription(.StringAtom("a\"b"), "\"a\\\"b\"")
    }
    
    func testDecimal() {
        assertDescription(.DecimalAtom(0.5),       "0.5")
        assertDescription(.DecimalAtom(13.37),     "13.37")
        assertDescription(.DecimalAtom(1.0 / 3.0), "0.333333333333333")
    }
    
    func testInteger() {
        assertDescription(.IntegerAtom(1), "1")
    }
    
    func testList() {
        assertDescription(.List([.StringAtom("a"), .StringAtom("b")]), "(\"a\" \"b\")")
    }
    
}
