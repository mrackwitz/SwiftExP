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
        let _ = try closure()
        XCTFail("Expected error \"\(expectedError)\", but succeeded")
    } catch let error where error is Error {
        XCTAssertTrue(error as! Error == expectedError, "Catched error \"\(error)\" from expected type, "
            + "but not the expected value: \"\(expectedError)\"")
    } catch {
        XCTFail("Catched error \"\(error)\", but not the expected type: \"\(expectedError)\"")
    }
}

class ParserTests: XCTestCase {
    
    // MARK: Atoms
    
    func test_001_int() {
        XCTAssertEqual(try! Parser.parse("1"), .IntegerAtom(1))
    }
    
    func test_002_rational() {
        XCTAssertEqual(try! Parser.parse("1/2"), .DecimalAtom(0.5))
    }
    
    func test_003_decimal() {
        XCTAssertEqual(try! Parser.parse("1.23"), .DecimalAtom(1.23))
    }
    
    func test_004_string() {
        XCTAssertEqual(try! Parser.parse("a"),  .StringAtom("a"))
        XCTAssertEqual(try! Parser.parse("ab"), .StringAtom("ab"))
    }
    
    func test_005_quotedEmptyString() {
        XCTAssertEqual(try! Parser.parse("\"\""),  .StringAtom(""))
    }
    
    func test_006_quotedString() {
        XCTAssertEqual(try! Parser.parse("\"a\""), .StringAtom("a"))
    }
    
    func test_006_quotedEscapedQuotationMark() {
        XCTAssertEqual(try! Parser.parse("\"\\\"\""), .StringAtom("\""))
    }
    
    func test_007_quotedSingleEscapeSequence() {
        XCTAssertEqual(try! Parser.parse("\"\\t\""),  .StringAtom("\t"))
        XCTAssertEqual(try! Parser.parse("\"\\n\""),  .StringAtom("\n"))
        XCTAssertEqual(try! Parser.parse("\"\\r\""),  .StringAtom("\r"))
        XCTAssertEqual(try! Parser.parse("\"\\'\""),  .StringAtom("'"))
        XCTAssertEqual(try! Parser.parse("\"\\\\\""), .StringAtom("\\"))
        XCTAssertEqual(try! Parser.parse("\"\\b\""),  .StringAtom("\u{8}")) // backspace
        XCTAssertEqual(try! Parser.parse("\"\\v\""),  .StringAtom("\u{b}")) // vertical tab
        XCTAssertEqual(try! Parser.parse("\"\\f\""),  .StringAtom("\u{c}")) // form-feed
    }
    
    func test_008_quotedUnicodeEscapeSequence() {
        XCTAssertEqual(try! Parser.parse("\"\\u2713\""), .StringAtom("✓"))
        XCTAssertEqual(try! Parser.parse("\"\\U0001F1FA\\U0001F1F8\""), .StringAtom("🇺🇸"))
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
            .StringAtom("a"),
            .StringAtom("b")
        ]))
    }
    
    func test_104_listOfListOfStrings() {
        XCTAssertEqual(try! Parser.parse("((a b) (c d))"), .List([
            .List([.StringAtom("a"), .StringAtom("b")]),
            .List([.StringAtom("c"), .StringAtom("d")]),
        ]))
    }
    
    func test_105_listOfListOfStrings() {
        XCTAssertEqual(try! Parser.parse("(( a ) (b))"), .List([
            .List([.StringAtom("a")]),
            .List([.StringAtom("b")]),
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
    
}
