//
//  Model.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

public enum Expression {
    case Atom(SwiftExP.Atom)
    case List([Expression])
    
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
                let jointXs = " ".join(xs.map { String($0) })
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
                let escaped = "\\\"".join(split(x.characters) { $0 == "\"" }.map { Swift.String($0) })
                return "\"\(escaped)\""
            case .Decimal(let x):
                return "\(x)"
            case .Integer(let x):
                return "\(x)"
        }
    }
}
