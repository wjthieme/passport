//
//  DG11.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation


class DG11 : DataGroup {
    
    private(set) var fullName : String?
    private(set) var personalNumber : String?
    private(set) var dateOfBirth : String?
    private(set) var placeOfBirth : String?
    private(set) var address : String?
    private(set) var telephone : String?
    private(set) var profession : String?
    private(set) var title : String?
    private(set) var personalSummary : String?
    private(set) var proofOfCitizenship : String?
    private(set) var tdNumbers : String?
    private(set) var custodyInfo : String?

    required init( _ data : [UInt8] ) throws {
        try super.init(data)
        datagroupType = .DG11
    }
        
    override func parse(_ data: [UInt8]) throws {
        var tag = try getNextTag()
        if tag != 0x5C {
            throw TagReaderError.invalidResponse
        }
        _ = try getNextValue()
        
        repeat {
            tag = try getNextTag()
            let val = try String( bytes:getNextValue(), encoding:.utf8)
            if tag == 0x5F0E {
                fullName = val
            } else if tag == 0x5F10 {
                personalNumber = val
            } else if tag == 0x5F11 {
                placeOfBirth = val
            } else if tag == 0x5F2B {
                dateOfBirth = val
            } else if tag == 0x5F42 {
                address = val
            } else if tag == 0x5F12 {
                telephone = val
            } else if tag == 0x5F13 {
                profession = val
            } else if tag == 0x5F14 {
                title = val
            } else if tag == 0x5F15 {
                personalSummary = val
            } else if tag == 0x5F16 {
                proofOfCitizenship = val
            } else if tag == 0x5F18 {
                tdNumbers = val
            } else if tag == 0x5F18 {
                custodyInfo = val
            }
        } while pos < data.count
    }
}

