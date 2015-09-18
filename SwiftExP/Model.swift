//
//  Model.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

public class Box<T> {
    public let unbox: T
    
    public init(_ content: T) {
        self.unbox = content
    }
}

extension Box : Equatable {
}

public func == <T>(lhs: Box<T>, rhs: Box<T>) -> Bool {
    preconditionFailure("Inner type '\(lhs.unbox.dynamicType)' is not equatable,"
        + "but was compared in '\(Box<T>.self)'.")
}

public func == <T where T: Equatable>(lhs: Box<T>, rhs: Box<T>) -> Bool {
    return lhs.unbox == rhs.unbox
}


public enum Expression {
    case Atom(SwiftExP.Atom)
    case List([Expression])
    case Attribute(identifier: SwiftExP.Atom, value: Box<Expression>)
    
    public init(_ string: String) {
        self = .Atom(.String(string))
    }
    
    public init(_ double: Double) {
        self = .Atom(.Decimal(double))
    }
    
    public init(_ int: Int) {
        self = .Atom(.Integer(int))
    }
    
    public init(_ array: [Expression]) {
        self = .List(array)
    }
    
    public init(_ identifier: SwiftExP.Atom, _ value: Expression) {
        self = .Attribute(identifier: identifier, value: Box(value))
    }
}

public enum Atom {
    case String(Swift.String)
    case Decimal(Double)
    case Integer(Int)
}


extension Expression : Equatable {
}

public func ==(lhs: Expression, rhs: Expression) -> Bool {
    switch (lhs, rhs) {
        case (.Atom(let l), .Atom(let r)):
            return l == r
        case (.List(let l), .List(let r)):
            return l == r
        case (.Attribute(let lIdentifier, let lValueBox), .Attribute(let rIdentifier, let rValueBox)):
            return lIdentifier == rIdentifier && lValueBox == rValueBox
        default:
            return false // you're comparing apples with oranges
    }
}

extension Atom : Equatable {
}

public func ==(lhs: Atom, rhs: Atom) -> Bool {
    switch (lhs, rhs) {
        case (.String(let l), .String(let r)):
            return l == r
        case (.Decimal(let l), .Decimal(let r)):
            return l == r
        case (.Integer(let l), .Integer(let r)):
            return l == r
        default:
            return false // you're comparing apples with oranges
    }
}


extension Expression : CustomStringConvertible {
    public var description: String {
        switch self {
            case .Atom(let x):
                return "\(x)"
            case .List(let xs):
                let jointXs = xs.map { $0.description }.joinWithSeparator(" ")
                return "(\(jointXs))"
            case .Attribute(let identifier, let valueBox):
                return "\(identifier)=\(valueBox.unbox)"
        }
    }
}

extension Atom : CustomStringConvertible {
    public var description: Swift.String {
        switch self {
            case .String(let x):
                if Parser.protectedChars.isDisjointWith(x.characters) {
                    return x
                } else {
                    let escaped = x.characters.split("\"").map { Swift.String($0) }.joinWithSeparator("\\\"")
                    return "\"\(escaped)\""
                }
            case .Decimal(let x):
                return "\(x)"
            case .Integer(let x):
                return "\(x)"
        }
    }
}


protocol PrettyPrintable {
    func prettyDescription(indentation: Swift.String) -> Swift.String
}

extension Expression : PrettyPrintable {
    public func prettyDescription(indentation: Swift.String = "") -> Swift.String {
        switch self {
        case .List(let xs):
            let incIndentation = indentation + "  "
            let listDescription = xs.reduce("") { (var accu, element) in
                if case .List(_) = element {
                    accu += "\n\(element.prettyDescription(incIndentation))"
                } else {
                    if !accu.isEmpty {
                        accu += " "
                    }
                    accu += "\(element)"
                }
                return accu
            }
            return indentation + "(" + listDescription + ")"
        default:
            return indentation + description
        }
    }
}

extension Atom : PrettyPrintable {
    public func prettyDescription(indentation: Swift.String = "") -> Swift.String {
        return indentation + description
    }
}
