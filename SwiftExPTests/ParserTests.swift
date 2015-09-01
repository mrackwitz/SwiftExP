//
//  SwiftExPTests.swift
//  SwiftExPTests
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

import XCTest
import SwiftExP


func SWXPAssertThrow<E, T where E: Equatable>(expectedError: E, @autoclosure _ closure: () throws -> (T), file: String = __FILE__, line: UInt = __LINE__) -> () {
    do {
        let _ = try closure()
        XCTFail("Expected error \"\(expectedError)\", but closure didn't threw "
            + "an error.", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expectedError, "Catched error is from expected "
            + "type, but not the expected case.", file: file, line: line)
    } catch {
        XCTFail("Catched error \"\(error)\", but not from the expected type "
            + "\"\(expectedError)\".", file: file, line: line)
    }
}


func SWXPAssertNoThrow(file: String = __FILE__, line: UInt = __LINE__, @noescape closure: () throws -> ()) {
    do {
        try closure()
    } catch {
        XCTFail("Catched unexpected error \"\(error)\".", file: file, line: line)
    }
}

func SWXPAssertNoThrow<T>(@autoclosure closure: () throws -> (T), file: String = __FILE__, line: UInt = __LINE__) -> T? {
    do {
        return try closure()
    } catch {
        XCTFail("Catched unexpected error \"\(error)\".", file: file, line: line)
    }
    return nil
}


public func SWXPAssertEqual<T : Equatable>(@autoclosure expression1: () throws -> T?, @autoclosure _ expression2: () throws -> T?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let exp1 = SWXPAssertNoThrow(expression1, file: file, line: line) ?? nil
    let exp2 = SWXPAssertNoThrow(expression2, file: file, line: line) ?? nil
    XCTAssertEqual(exp1, exp2, message, file: file, line: line)
}


class ParserTests: XCTestCase {
    
    // MARK: Atoms
    
    func test_001_int() {
        SWXPAssertEqual(try Parser.parse("1"), Expression(1))
    }
    
    func test_002_rational() {
        SWXPAssertEqual(try Parser.parse("1/2"), Expression(0.5))
    }
    
    func test_003_decimal() {
        SWXPAssertEqual(try Parser.parse("1.23"), Expression(1.23))
    }
    
    func test_004_string() {
        SWXPAssertEqual(try Parser.parse("a"),  Expression("a"))
        SWXPAssertEqual(try Parser.parse("ab"), Expression("ab"))
    }
    
    func test_005_quotedEmptyString() {
        SWXPAssertEqual(try Parser.parse("\"\""),  Expression(""))
    }
    
    func test_006_quotedString() {
        SWXPAssertEqual(try Parser.parse("\"a\""), Expression("a"))
    }
    
    func test_006_quotedEscapedQuotationMark() {
        SWXPAssertEqual(try Parser.parse("\"\\\"\""), Expression("\""))
    }
    
    func test_007_quotedSingleEscapeSequence() {
        SWXPAssertEqual(try Parser.parse("\"\\t\""),  Expression("\t"))
        SWXPAssertEqual(try Parser.parse("\"\\n\""),  Expression("\n"))
        SWXPAssertEqual(try Parser.parse("\"\\r\""),  Expression("\r"))
        SWXPAssertEqual(try Parser.parse("\"\\'\""),  Expression("'"))
        SWXPAssertEqual(try Parser.parse("\"\\\\\""), Expression("\\"))
        SWXPAssertEqual(try Parser.parse("\"\\b\""),  Expression("\u{8}")) // backspace
        SWXPAssertEqual(try Parser.parse("\"\\v\""),  Expression("\u{b}")) // vertical tab
        SWXPAssertEqual(try Parser.parse("\"\\f\""),  Expression("\u{c}")) // form-feed
    }
    
    func test_008_quotedUnicodeEscapeSequence() {
        SWXPAssertEqual(try Parser.parse("\"\\u2713\""), Expression("✓"))
        SWXPAssertEqual(try Parser.parse("\"\\U0001F1FA\\U0001F1F8\""), Expression("🇺🇸"))
    }
    
    func test_009_quotedNonEscapedLineWraps() {
        SWXPAssertEqual(try Parser.parse("\"\n\""),   Expression("\n"))
        SWXPAssertEqual(try Parser.parse("\"\n\r\""), Expression("\n\r"))
        SWXPAssertEqual(try Parser.parse("\"\r\""),   Expression("\r"))
        SWXPAssertEqual(try Parser.parse("\"\r\n\""), Expression("\r\n"))
    }
        
    func test_009_quotedEscapedLineWraps() {
        SWXPAssertEqual(try Parser.parse("\"\\\n\""),   Expression(""))
        SWXPAssertEqual(try Parser.parse("\"\\\n\r\""), Expression(""))
        SWXPAssertEqual(try Parser.parse("\"\\\r\""),   Expression(""))
        // TODO: Doesn't work
        //SWXPAssertEqual(try Parser.parse("\"\\\r\n\""), Expression(""))
    }
    
    func test_010_maintainedQuotationChars() {
        SWXPAssertEqual(try Parser.parse("[a b]"), Expression("[a b]"))
    }
    
    // MARK: Lists
    
    func test_101_emptyList() {
        SWXPAssertEqual(try Parser.parse("()"),  Expression([]))
        SWXPAssertEqual(try Parser.parse("( )"), Expression([]))
    }
    
    func test_102_listOfLists() {
        SWXPAssertEqual(try Parser.parse("(()())"), Expression([
            .List([]),
            .List([]),
        ]))
        SWXPAssertEqual(try Parser.parse("(() ())"), Expression([
            .List([]),
            .List([]),
        ]))
    }
    
    func test_103_listOfStrings() {
        SWXPAssertEqual(try Parser.parse("(a b)"), Expression([
            Expression("a"),
            Expression("b")
        ]))
    }
    
    func test_104_listOfListOfStrings() {
        SWXPAssertEqual(try Parser.parse("((a b) (c d))"), Expression([
            .List([Expression("a"), Expression("b")]),
            .List([Expression("c"), Expression("d")]),
        ]))
    }
    
    func test_105_listOfListOfStrings() {
        SWXPAssertEqual(try Parser.parse("(( a ) (b))"), Expression([
            .List([Expression("a")]),
            .List([Expression("b")]),
        ]))
    }
    
    // MARK: Assignment
    
    func test_211_assignment() {
        SWXPAssertEqual(try Parser.parse("\"a\"=1"), Expression(Atom.String("a"), Expression(1)))
    }
    
    // MARK: Errors

    func test_201_unexpectedEOS() {
        SWXPAssertThrow(Error.UnexpectedEOS, try Parser.parse(""))
        SWXPAssertThrow(Error.UnexpectedEOS, try Parser.parse("\"\\u\""))
    }
    
    func test_202_illegalNumberFormat() {
        SWXPAssertThrow(Error.IllegalNumberFormat(numberString: "1."),   try Parser.parse("1."))
        SWXPAssertThrow(Error.IllegalNumberFormat(numberString: "1./2"), try Parser.parse("1./2"))
        SWXPAssertThrow(Error.IllegalNumberFormat(numberString: "1/2."), try Parser.parse("1/2."))
        SWXPAssertThrow(Error.IllegalNumberFormat(numberString: "1.2/"), try Parser.parse("1.2/"))
    }

    func test_203_illegalEscapeSequence() {
        SWXPAssertThrow(Error.IllegalEscapeSequence(escapeSequence: "\\i"), try Parser.parse("\\i"))
        SWXPAssertThrow(Error.IllegalEscapeSequence(escapeSequence: "\\i"), try Parser.parse("\"\\i\""))
    }
    
    func test_204_nonTerminatedList() {
        SWXPAssertThrow(Error.NonTerminatedList, try Parser.parse("("))
        SWXPAssertThrow(Error.NonTerminatedList, try Parser.parse("(()"))
        SWXPAssertThrow(Error.NonTerminatedList, try Parser.parse("(()"))
    }
    
    func test_205_nonTerminatedQuotedString() {
        SWXPAssertThrow(Error.NonTerminatedQuotedString, try Parser.parse("\""))
        SWXPAssertThrow(Error.NonTerminatedQuotedString, try Parser.parse("(\"a\" \")"))
    }
    
    func test_206_missingAssignmentValue() {
        SWXPAssertThrow(Error.MissingAssigmentValue, try Parser.parse("a="))
        SWXPAssertThrow(Error.MissingAssigmentValue, try Parser.parse("a= "))
    }
    
    func test_207_illegalHexCharacter() {
        SWXPAssertThrow(Error.IllegalHexCharacter(char: "x"), try Parser.parse("\"\\uxxxx\""))
        SWXPAssertThrow(Error.IllegalHexCharacter(char: " "), try Parser.parse("\"\\u    \""))
        SWXPAssertThrow(Error.IllegalHexCharacter(char: " "), try Parser.parse("\"\\u    \""))
    }
    
    // MARK: Fixtures
    
    func test_301_swiftAstDump() {
        let bundle = NSBundle(forClass: ParserTests.self)
        let path = bundle.pathForResource("test", ofType: "swift-ast")!
        SWXPAssertNoThrow {
            let expr = try Parser.parse(contentsOfFile: path)
            SWXPAssertEqual(String(expr), "")
        }
    }
    
}
