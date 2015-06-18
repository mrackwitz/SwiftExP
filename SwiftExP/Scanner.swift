//
//  Scanner.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

public struct Scanner {
    
    public enum Error : ErrorType {
        /// Scanner reached end of string
        case EOS
    }
    
    var string: String
    var index: String.Index
    
    public init(string: String) {
        self.string = string
        self.index = string.startIndex
    }
    
    /**
    Returns whether the cursor has reached the end
    */
    public var eos: Bool {
        return index == string.endIndex
    }
    
    /**
    Returns the current char or nil
    */
    public var currentChar: Character? {
        if eos {
            return nil
        } else {
            return string[index]
        }
    }
    
    /**
    Returns the current char and advances the cursor by one or
    throws an error when the end of string is reached.
    */
    public mutating func readChar() throws -> Character {
        if eos {
            throw Error.EOS
        } else {
            let char = currentChar
            try! skipChar()
            return char!
        }
    }
    
    /**
    Advances the cursor by one or throws an error when the end of
    string is reached.
    */
    public mutating func skipChar() throws {
        if eos {
            throw Error.EOS
        } else {
            index = advance(index, 1)
        }
    }
    
    /**
    Reads the given number of chars and advances the cursor or
    throws an error when the end of string is reached before.
    */
    public mutating func readChars(length: Int) throws -> String {
        let advancedIndex = advance(index, length, string.endIndex)
        if distance(index, advancedIndex) < length {
            throw Error.EOS
        }
        let chars = string[index..<advancedIndex]
        index = advancedIndex
        return chars
    }
    
}

extension String {
    /**
    Read until a given character appears or the end of the string is reached
    
    - parameter char  The character until which should be read
    */
    public func readUntil(char: Character) -> (substring: String?, remainder: String) {
        let parts = split(self.characters, maxSplit: 1, allowEmptySlices: false) { $0 == char }
        if parts.count > 1 {
            return (String(parts[0]), String(parts[1]))
        } else {
            return (nil, self)
        }
    }
}
