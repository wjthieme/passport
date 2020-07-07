//
//  DataGroup.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation

class DataGroup {
    var datagroupType: TagDataGroup?

    /// Body contains the actual data
    private(set) var body : [UInt8] = []

    /// Data contains the whole DataGroup data (as that is what the hash is calculated from
    private var data : [UInt8] = []

    var pos = 0
    
    required init( _ data : [UInt8] ) throws {
        self.data = data
        
        // Skip the first byte which is the header byte
        pos = 1
        let _ = try getNextLength()
        self.body = [UInt8](data[pos...])
        
        try parse(data)
    }
    
    func parse( _ data:[UInt8] ) throws {
        throw NSError(domain: "notImplemented", code: 0, userInfo: nil)
    }
    
    func getNextTag() throws -> Int {
        var tag = 0
        if binToHex(data[pos]) & 0x0F == 0x0F {
            tag = Int(binToHex([UInt8](data[pos..<pos+2])))
            pos += 2
        } else {
            tag = Int(data[pos])
            pos += 1
        }
        return tag
    }

    func getNextLength() throws -> Int  {
        let end = pos+4 < data.count ? pos+4 : data.count
        let (len, lenOffset) = try asn1Length([UInt8](data[pos..<end]))
        pos += lenOffset
        return len
    }
    
    func getNextValue() throws -> [UInt8] {
        let length = try getNextLength()
        let value = [UInt8](data[pos ..< pos+length])
        pos += length
        return value
    }
    
    private func hash( _ hashAlgorythm: String ) -> [UInt8]  {
        var ret : [UInt8] = []
        if hashAlgorythm == "SHA256" {
            ret = SHA256Hash(self.data)
        } else if hashAlgorythm == "SHA1" {
            ret = SHA1Hash(self.data)
        }
        
        return ret
    }

}
