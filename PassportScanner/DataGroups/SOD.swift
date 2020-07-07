//
//  SOD.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation

class SOD : DataGroup {
    private(set) var pkck7CertificateData : [UInt8] = []
    
     required init( _ data : [UInt8] ) throws {
        try super.init(data)
        datagroupType = .SOD
    }

    override func parse(_ data: [UInt8]) throws {
        self.pkck7CertificateData = try getNextValue()
    }
}
