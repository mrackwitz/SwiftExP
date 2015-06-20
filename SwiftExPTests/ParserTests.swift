//
//  SwiftExPTests.swift
//  SwiftExPTests
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

import XCTest
import SwiftExP

func SWEXPThrow(expectedError: Error, @autoclosure _ closure: () throws -> (Expression)) -> () {
    do {
        let unexpectedValue = try closure()
        XCTFail("Expected error \"\(expectedError)\", but succeeded with value "
            + "\(unexpectedValue)\".")
    } catch let error where error is Error {
        XCTAssertEqual(error as! Error, expectedError, "Catched error is from expected type, "
            + "but not the expected case.")
    } catch {
        XCTFail("Catched error \"\(error)\", but not the expected type: \"\(expectedError)\"")
    }
}

class ParserTests: XCTestCase {
    
    // MARK: Atoms
    
    func test_001_int() {
        XCTAssertEqual(try! Parser.parse("1"), Expression(1))
    }
    
    func test_002_rational() {
        XCTAssertEqual(try! Parser.parse("1/2"), Expression(0.5))
    }
    
    func test_003_decimal() {
        XCTAssertEqual(try! Parser.parse("1.23"), Expression(1.23))
    }
    
    func test_004_string() {
        XCTAssertEqual(try! Parser.parse("a"),  Expression("a"))
        XCTAssertEqual(try! Parser.parse("ab"), Expression("ab"))
    }
    
    func test_005_quotedEmptyString() {
        XCTAssertEqual(try! Parser.parse("\"\""),  Expression(""))
    }
    
    func test_006_quotedString() {
        XCTAssertEqual(try! Parser.parse("\"a\""), Expression("a"))
    }
    
    func test_006_quotedEscapedQuotationMark() {
        XCTAssertEqual(try! Parser.parse("\"\\\"\""), Expression("\""))
    }
    
    func test_007_quotedSingleEscapeSequence() {
        XCTAssertEqual(try! Parser.parse("\"\\t\""),  Expression("\t"))
        XCTAssertEqual(try! Parser.parse("\"\\n\""),  Expression("\n"))
        XCTAssertEqual(try! Parser.parse("\"\\r\""),  Expression("\r"))
        XCTAssertEqual(try! Parser.parse("\"\\'\""),  Expression("'"))
        XCTAssertEqual(try! Parser.parse("\"\\\\\""), Expression("\\"))
        XCTAssertEqual(try! Parser.parse("\"\\b\""),  Expression("\u{8}")) // backspace
        XCTAssertEqual(try! Parser.parse("\"\\v\""),  Expression("\u{b}")) // vertical tab
        XCTAssertEqual(try! Parser.parse("\"\\f\""),  Expression("\u{c}")) // form-feed
    }
    
    func test_008_quotedUnicodeEscapeSequence() {
        XCTAssertEqual(try! Parser.parse("\"\\u2713\""), Expression("✓"))
        XCTAssertEqual(try! Parser.parse("\"\\U0001F1FA\\U0001F1F8\""), Expression("🇺🇸"))
    }
    
    func test_009_quotedNonEscapedLineWraps() {
        XCTAssertEqual(try! Parser.parse("\"\n\""),   Expression("\n"))
        XCTAssertEqual(try! Parser.parse("\"\n\r\""), Expression("\n\r"))
        XCTAssertEqual(try! Parser.parse("\"\r\""),   Expression("\r"))
        XCTAssertEqual(try! Parser.parse("\"\r\n\""), Expression("\r\n"))
    }
        
    func test_009_quotedEscapedLineWraps() {
        XCTAssertEqual(try! Parser.parse("\"\\\n\""),   Expression(""))
        XCTAssertEqual(try! Parser.parse("\"\\\n\r\""), Expression(""))
        XCTAssertEqual(try! Parser.parse("\"\\\r\""),   Expression(""))
        // TODO: Doesn't work
        //XCTAssertEqual(try! Parser.parse("\"\\\r\n\""), Expression(""))
    }
    
    // MARK: Lists
    
    func test_101_emptyList() {
        XCTAssertEqual(try! Parser.parse("()"), .List([]))
        XCTAssertEqual(try! Parser.parse("( )"), .List([]))
    }
    
    func test_102_listOfLists() {
        XCTAssertEqual(try! Parser.parse("(()())"), .List([
            .List([]),
            .List([]),
        ]))
        XCTAssertEqual(try! Parser.parse("(() ())"), .List([
            .List([]),
            .List([]),
        ]))
    }
    
    func test_103_listOfStrings() {
        XCTAssertEqual(try! Parser.parse("(a b)"), .List([
            Expression("a"),
            Expression("b")
        ]))
    }
    
    func test_104_listOfListOfStrings() {
        XCTAssertEqual(try! Parser.parse("((a b) (c d))"), .List([
            .List([Expression("a"), Expression("b")]),
            .List([Expression("c"), Expression("d")]),
        ]))
    }
    
    func test_105_listOfListOfStrings() {
        XCTAssertEqual(try! Parser.parse("(( a ) (b))"), .List([
            .List([Expression("a")]),
            .List([Expression("b")]),
        ]))
    }
    
    // MARK: Errors

    func test_201_unexpectedEOS() {
        SWEXPThrow(Error.UnexpectedEOS, try Parser.parse(""))
        SWEXPThrow(Error.UnexpectedEOS, try Parser.parse("\"\\u\""))
    }
    
    func test_202_illegalNumberFormat() {
        SWEXPThrow(Error.IllegalNumberFormat(numberString: "1."),   try Parser.parse("1."))
        SWEXPThrow(Error.IllegalNumberFormat(numberString: "1./2"), try Parser.parse("1./2"))
        SWEXPThrow(Error.IllegalNumberFormat(numberString: "1/2."), try Parser.parse("1/2."))
        SWEXPThrow(Error.IllegalNumberFormat(numberString: "1.2/"), try Parser.parse("1.2/"))
    }

    func test_203_illegalEscapeSequence() {
        SWEXPThrow(Error.IllegalEscapeSequence(escapeSequence: "\\i"), try Parser.parse("\\i"))
        SWEXPThrow(Error.IllegalEscapeSequence(escapeSequence: "\\i"), try Parser.parse("\"\\i\""))
    }
    
    func test_204_nonTerminatedList() {
        SWEXPThrow(Error.NonTerminatedList, try Parser.parse("("))
        SWEXPThrow(Error.NonTerminatedList, try Parser.parse("(()"))
        SWEXPThrow(Error.NonTerminatedList, try Parser.parse("(()"))
    }
    
    func test_205_nonTerminatedQuotedString() {
        SWEXPThrow(Error.NonTerminatedQuotedString, try Parser.parse("\""))
        SWEXPThrow(Error.NonTerminatedQuotedString, try Parser.parse("(\"a\" \")"))
    }
    
    func test_206_illegalHexCharacter() {
        SWEXPThrow(Error.IllegalHexCharacter(char: "x"), try Parser.parse("\"\\uxxxx\""))
        SWEXPThrow(Error.IllegalHexCharacter(char: " "), try Parser.parse("\"\\u    \""))
    }
    
    // MARK: Fixtures
    
    func test_301_swiftAstDump() {
        let bundle = NSBundle(forClass: ParserTests.self)
        let path = bundle.pathForResource("test", ofType: "swift-ast")!
        let expr = try! Parser.parse(contentsOfFile: path)
        XCTAssertEqual(String(expr), "")
    }
    
}
