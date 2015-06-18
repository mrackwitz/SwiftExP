//
//  Parser+File.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 18.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

import Foundation

extension Parser {
    
    public static func parse(contentsOfFile path: String) throws -> Expression {
        let data = NSData(contentsOfFile: path)!
        let nsString = NSString(data: data, encoding: NSUTF8StringEncoding)!
        let string = String(nsString)
        return try self.parse(string)
    }
    
}
