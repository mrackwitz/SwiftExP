//
//  Parser+File.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 18.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

import Foundation

extension Optional {
    func flatMap<U>(@noescape f: (T) throws -> U?) rethrows -> U? {
        if case .Some(let inner) = self {
            return try f(inner)
        }
        return .None
    }
}

extension Parser {
    
    public static func parse(contentsOfFile path: String) throws -> Expression? {
        return try NSData(contentsOfFile: path).flatMap { (data) in
            try NSString(data: data, encoding: NSUTF8StringEncoding).flatMap { (nsString) in
                let string = String(nsString)
                return try self.parse(string)
            }
        }
    }
    
}
