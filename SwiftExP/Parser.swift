//
//  Parser.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//


public enum Error : ErrorType {
    case UnexpectedEOS
    case IllegalNumberFormat(numberString: String)
    case IllegalEscapeSequence(escapeSequence: String)
    case NonTerminatedList
    case NonTerminatedQuotedString
    case MissingAssigmentValue
    case IllegalHexCharacter(char: Character)
}


extension Error : Equatable {
}

public func ==(lhs: Error, rhs: Error) -> Bool {
    switch (lhs, rhs) {
        case (.UnexpectedEOS, .UnexpectedEOS):
            return true
        case (.IllegalNumberFormat(let l), .IllegalNumberFormat(let r)):
            return l == r
        case (.IllegalEscapeSequence(let l), .IllegalEscapeSequence(let r)):
            return l == r
        case (.NonTerminatedList, .NonTerminatedList):
            return true
        case (.NonTerminatedQuotedString, .NonTerminatedQuotedString):
            return true
        case (.IllegalHexCharacter(let l), .IllegalHexCharacter(let r)):
            return l == r
        default:
            return false
    }
}


extension Error : CustomStringConvertible {
    public var description: String {
        return "\(Error.self).\(self.name)<:\(_code)>."
    }
    
    public var name: String {
        switch self {
            case .UnexpectedEOS:
                return "UnexpectedEOS"
            case .IllegalNumberFormat(let x):
                return "IllegalNumberFormat(\(x))"
            case .IllegalEscapeSequence(let x):
                return "IllegalEscapeSequence(\(x))"
            case .NonTerminatedList:
                return "NonTerminatedList"
            case .NonTerminatedQuotedString:
                return "NonTerminatedQuotedString"
            case .MissingAssigmentValue:
                return "MissingAssigmentValue"
            case .IllegalHexCharacter(let x):
                return "IllegalHexCharacter(\(x))"
        }
    }
}



public struct Parser {
    
    var scanner: Scanner
    
    /**
    Parse the given string without the need of instantiating a Parser
    
    - parameter string  The string to parse
    */
    public static func parse(string: String) throws -> Expression {
        var parser = self(string: string)
        return try parser.parse()
    }
    
    /**
    Instantiate a Parser for a given string
    
    - parameter string  The string to parse
    */
    public init(string: String) {
        self.scanner = Scanner(string: string)
    }
    
    /**
    Parses the given string
    */
    public mutating func parse() throws -> Expression {
        do {
            return try parseExpression()!
        } catch Scanner.Error.EOS {
            throw Error.UnexpectedEOS
        }
    }
    
    // MARK: Expression level
    
    mutating func parseExpression() throws -> Expression? {
        try skipWhitespace()
        switch scanner.currentChar {
            case "("?:
                try scanner.skipChar()
                return try parseList()
            case ")"?:
                try scanner.skipChar()
                return nil
            case nil:
                throw Scanner.Error.EOS
            default:
                let atom = try parseAtom()
                if let char = scanner.currentChar where char == Parser.assignmentChar {
                    do {
                        try scanner.skipChar()
                        let maybeValue = try parseExpression()
                        if let value = maybeValue {
                            return Expression(atom, value)
                        } else {
                            throw Error.MissingAssigmentValue
                        }
                    } catch Scanner.Error.EOS {
                        throw Error.MissingAssigmentValue
                    }
                } else {
                    return .Atom(atom)
                }
        }
    }
    
    mutating func parseList() throws -> Expression {
        do {
            var list = [Expression]()
            while let expr = try parseExpression() {
                list.append(expr)
            }
            return Expression(list)
        } catch Scanner.Error.EOS {
            throw Error.NonTerminatedList
        }
    }
    
    mutating func parseAtom() throws -> Atom {
        if Parser.quotationChars.contains(scanner.currentChar!) {
            return try .String(readQuotedString())
        } else {
            let literalString = try readLiteral()
            precondition(literalString != "")
            return try parseLiteral(literalString)
        }
    }
    
    func parseLiteral(literalString: String) throws -> Atom {
        let literalStringSet = Set(literalString.characters)
        if literalStringSet.isSubsetOf(Parser.numberChars) {
            if literalStringSet.isSubsetOf(Parser.integerChars) {
                return parseInteger(literalString)
            } else if literalStringSet.isSubsetOf(Parser.rationalChars) {
                return try parseRational(literalString)
            } else if literalStringSet.isSubsetOf(Parser.decimalChars) {
                return try parseDecimal(literalString)
            } else {
                throw Error.IllegalNumberFormat(numberString: literalString)
            }
        } else {
            return .String(literalString)
        }
    }
    
    func parseInteger(string: String) -> Atom {
        return .Integer(Int(string)!)
    }
    
    func parseRational(string: String) throws -> Atom {
        let (maybeNumeratorStr, denominatorStr) = string.readUntil(Parser.divisionOperatorChar)
        if denominatorStr.isEmpty {
            throw Error.IllegalNumberFormat(numberString: string)
        }
        if let numeratorStr = maybeNumeratorStr {
            let numerator = Int(numeratorStr)!
            let denominator = Int(denominatorStr)!
            return .Decimal(Double(numerator) / Double(denominator))
        } else {
            throw Scanner.Error.EOS
        }
    }
    
    func parseDecimal(string: String) throws -> Atom {
        let (maybeDecimalStr, mantissaStr) = string.readUntil(Parser.decimalSeparatorChar)
        if mantissaStr.isEmpty {
            throw Error.IllegalNumberFormat(numberString: string)
        }
        if let decimalStr = maybeDecimalStr {
            let decimal = Int(decimalStr)!
            let mantissa = Int(mantissaStr)!
            let divident = (0 ..< Int(mantissaStr.characters.count)).reduce(1) { (a: Int, _) in return a * 10 }
            return .Decimal(Double(decimal) + (Double(mantissa) / Double(divident)))
        } else {
            throw Scanner.Error.EOS
        }
    }
    
    static let assignmentChar:  Character      = "="
    static let whitespaceChars: Set<Character> = Set(" \r\t\n".characters)
    static let quotationChars:  Set<Character> = Set("'\"".characters)
    static let listChars:       Set<Character> = Set("()=".characters)
    static let protectedChars = [whitespaceChars, quotationChars, listChars].reduce(Set()) { $0.union($1) }
    
    static let digitChars: Set<Character> = Set("0123456789".characters)
    static let decimalSeparatorChar: Character = "."
    static let divisionOperatorChar: Character = "/"
    static let integerChars  = digitChars
    static let decimalChars  = digitChars.union(Set([decimalSeparatorChar]))
    static let rationalChars = digitChars.union(Set([divisionOperatorChar]))
    static let numberChars   = [integerChars, decimalChars, rationalChars].reduce(Set()) { $0.union($1) }
    
    // MARK: Lexical level
    
    mutating func readQuotedString() throws -> String {
        // Skip the opening quotation mark
        let quotationChar = try scanner.readChar()
        
        var buffer = ""
        while let char = scanner.currentChar where char != quotationChar {
            try scanner.skipChar()
            if char == "\\" {
                buffer += try readEscapeSequence()
            } else {
                buffer.append(char)
            }
        }
        
        // Skip the closing quotation mark if given, otherwise fail
        if scanner.eos {
            throw Error.NonTerminatedQuotedString
        } else {
            try scanner.skipChar()
        }
        
        return buffer
    }
    
    mutating func readLiteral() throws -> String {
        var buffer = ""
        while let char = scanner.currentChar where !Parser.protectedChars.contains(char) {
            try scanner.skipChar()
            if char == "\\" {
                buffer += try readEscapeSequence()
            } else {
                buffer.append(char)
            }
        }
        return buffer
    }

    mutating func readEscapeSequence() throws -> String {
        let char = try scanner.readChar()
        switch char {
            case "t":  return "\t"
            case "n":  return "\n"
            case "r":  return "\r"
            case "'":  return "'"
            case "\"": return "\""
            case "\\": return "\\"
            case "b":  return "\u{8}" // backspace
            case "v":  return "\u{b}" // vertical tab
            case "f":  return "\u{c}" // form-feed
            case "\r":
                if scanner.currentChar == "\n" {
                    try scanner.skipChar()
                }
                return ""
            case "\n":
                if scanner.currentChar == "\r" {
                    try scanner.skipChar()
                }
                return ""
            case "u", "U":
                let sequence = try scanner.readChars(char == "u" ? 4 : 8)
                let codePoint = try Int.fromHexString(sequence)
                let unicodeChar = Character(UnicodeScalar(codePoint))
                return "\(unicodeChar)"
            default:
                throw Error.IllegalEscapeSequence(escapeSequence: "\\\(char)")
        }
    }

    mutating func skipWhitespace() throws {
        while let char = scanner.currentChar where Parser.whitespaceChars.contains(char) {
            try scanner.skipChar()
        }
    }
    
}

extension Int {
    static func fromHexString(string: String) throws -> Int {
        var base = 1
        var number = 0
        for char: Character in string.characters.reverse() {
            let charValue = try char.hexCharacterValue()
            number += base * charValue
            base *= 16
        }
        return number
    }
}

extension Character {
    func hexCharacterValue() throws -> Int {
        switch self {
            case "0":      return 0
            case "1":      return 1
            case "2":      return 2
            case "3":      return 3
            case "4":      return 4
            case "5":      return 5
            case "6":      return 6
            case "7":      return 7
            case "8":      return 8
            case "9":      return 9
            case "a", "A": return 10
            case "b", "B": return 11
            case "c", "C": return 12
            case "d", "D": return 13
            case "e", "E": return 14
            case "f", "F": return 15
            default:       throw Error.IllegalHexCharacter(char: self)
        }
    }
}
