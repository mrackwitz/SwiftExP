//
//  Model.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 15.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

public enum Expression {
    case StringAtom(String)
    case DecimalAtom(Double)
    case IntegerAtom(Int)
    case List([Expression])
}


extension Expression : Equatable {
}

public func ==(lhs: Expression, rhs: Expression) -> Bool {
    switch (lhs, rhs) {
        case (.StringAtom(let l), .StringAtom(let r)):
            return l == r
        case (.DecimalAtom(let l), .DecimalAtom(let r)):
            return l == r
        case (.IntegerAtom(let l), .IntegerAtom(let r)):
            return l == r
        case (.List(let l), .List(let r)):
            return l == r
        default:
            return false // you're comparing apples with oranges
    }
}


extension Expression : CustomStringConvertible {
    public var description: String {
        switch self {
            case .StringAtom(let x):
                let escaped = "\\\"".join(split(x.characters) { $0 == "\"" }.map { String($0) })
                return "\"\(escaped)\""
            case .DecimalAtom(let x):
                return "\(x)"
            case .IntegerAtom(let x):
                return "\(x)"
            case .List(let xs):
                let jointXs = " ".join(xs.map { String($0) })
                return "(\(jointXs))"
        }
    }
}
