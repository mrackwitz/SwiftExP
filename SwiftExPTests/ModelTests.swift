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
        assertDescription(.Atom(.String("a")),    "a")
        assertDescription(.Atom(.String("a b")),  "\"a b\"")
        assertDescription(.Atom(.String("a\"b")), "\"a\\\"b\"")
    }
    
    func testDecimal() {
        assertDescription(.Atom(.Decimal(0.5)),       "0.5")
        assertDescription(.Atom(.Decimal(13.37)),     "13.37")
        assertDescription(.Atom(.Decimal(1.0 / 3.0)), "0.333333333333333")
    }
    
    func testInteger() {
        assertDescription(.Atom(.Integer(1)), "1")
    }
    
    func testList() {
        assertDescription(.List([.Atom(.String("a")), .Atom(.String("b"))]), "(a b)")
    }
    
    func testAttribute() {
        assertDescription(Expression(.String("a"), Expression(1)),   "a=1")
        assertDescription(Expression(.String("a b"), Expression(1)), "\"a b\"=1")
    }
    
}
