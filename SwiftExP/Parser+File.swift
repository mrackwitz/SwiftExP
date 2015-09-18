//
//  Parser+File.swift
//  SwiftExP
//
//  Created by Marius Rackwitz on 18.6.15.
//  Copyright © 2015 Marius Rackwitz. All rights reserved.
//

import Foundation


extension Parser {
    
    public static func parse(contentsOfFile path: String) throws -> Expression? {
        return try NSData(contentsOfFile: path).flatMap { (data) in
            try NSString(data: data, encoding: NSUTF8StringEncoding).flatMap { (nsString) in
                let string = nsString as String
                return try self.parse(string)
            }
        }
    }
    
}
