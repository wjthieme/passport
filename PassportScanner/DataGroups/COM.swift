//
//  DataGroupParser.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation

class COM : DataGroup {
    private(set) var version : String = "Unknown"
    private(set) var unicodeVersion : String = "Unknown"
    private(set) var dataGroupsPresent : [TagDataGroup] = []
    
    required init( _ data : [UInt8] ) throws {
        try super.init(data)
        datagroupType = .COM
    }

    override func parse(_ data: [UInt8]) throws {
        var tag = try getNextTag()
        if tag != 0x5F01 {
            throw TagReaderError.invalidResponse
        }
        
        // Version is 4 bytes (ascii) - AABB
        // AA is major number, BB is minor number
        // e.g.  48 49 48 55 -> 01 07 -> 1.7
        var versionBytes = try getNextValue()
        if versionBytes.count == 4 {
            let aa = Int( String(cString: Array(versionBytes[0..<2] + [0]) )) ?? -1
            let bb = Int( String(cString: Array(versionBytes[2...] + [0])) ) ?? -1
            if aa != -1 && bb != -1 {
                version = "\(aa).\(bb)"
            }
        }
        tag = try getNextTag()
        if tag != 0x5F36 {
            throw TagReaderError.invalidResponse
        }
        
        versionBytes = try getNextValue()
        if versionBytes.count == 6 {
            let aa = Int( String(cString: Array(versionBytes[0..<2] + [0])) ) ?? -1
            let bb = Int( String(cString: Array(versionBytes[2..<4] + [0])) ) ?? -1
            let cc = Int( String(cString: Array(versionBytes[4...]) + [0]) ) ?? -1
            if aa != -1 && bb != -1 && cc != -1 {
                unicodeVersion = "\(aa).\(bb).\(cc)"
            }
        }

        tag = try getNextTag()
        if tag != 0x5C {
            throw TagReaderError.invalidResponse
        }
        
        let vals = try getNextValue()
        for v in vals {
            guard let dataGroup = TagDataGroup(rawValue: Int(v)) else { continue }
            dataGroupsPresent.append(dataGroup)
        }
    }
}



@available(iOS 13, *)
public enum DocTypeEnum: String {
    case TD1
    case TD2
    case OTHER
    
    var desc: String {
        get {
            return self.rawValue
        }
    }
}
