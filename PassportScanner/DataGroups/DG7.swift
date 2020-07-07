//
//  DG7.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import UIKit

class DG7 : DataGroup {
    
    private(set) var imageData : [UInt8] = []

    required init( _ data : [UInt8] ) throws {
        try super.init(data)
        datagroupType = .DG7
    }
    
    func getImage() -> UIImage? {
        if imageData.count == 0 {
            return nil
        }
        
        let image = UIImage(data:Data(imageData) )
        return image
    }

    
    override func parse(_ data: [UInt8]) throws {
        var tag = try getNextTag()
        if tag != 0x02 {
            throw TagReaderError.invalidResponse
        }
        _ = try getNextValue()
        
        tag = try getNextTag()
        if tag != 0x5F43 {
            throw TagReaderError.invalidResponse
        }
        
        imageData = try getNextValue()
    }
}
