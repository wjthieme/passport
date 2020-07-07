//
//  TagCommands.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation
import CoreNFC

enum TagCommand: CustomStringConvertible {
//    case selectApplication
    case getChallenge
    case doAuthentication(_ data: [UInt8])
    case selectFile(_ dataGroup: TagDataGroup)
    case readHeader
    case readFile(offset: [UInt8], readAmount: UInt8)
    
    private var data: [UInt8] {
        switch self {
        case .getChallenge: return [0x00, 0x84, 0x00, 0x00, 0x08]
        case .doAuthentication(let data): return [0x00, 0x82, 0x00, 0x00, 0x28] + data + [0x28]
        case .selectFile(let dataGroup): return [0x00, 0xA4, 0x02, 0x0C, 0x02] + dataGroup.fileId
        case .readHeader: return [0x00, 0xB0, 0x00, 0x00, 0x00, 0x00, 0x04]
        case .readFile(let offset, let readAmount): return [0x00, 0xB0] + offset + [readAmount]
        }
    }
    
    var cmd: NFCISO7816APDU { return NFCISO7816APDU(data: Data(data))! }
    var description: String { return binToHexRep(data, separator: " ") }
    
}

enum TagDataGroup: Int {
    
    case COM = 0x60
    case DG1 = 0x61
    case DG2 = 0x75
    case DG3 = 0x63
    case DG4 = 0x76
    case DG5 = 0x65
    case DG6 = 0x66
    case DG7 = 0x67
    case DG8 = 0x68
    case DG9 = 0x69
    case DG10 = 0x6A
    case DG11 = 0x6B
    case DG12 = 0x6C
    case DG13 = 0x6D
    case DG14 = 0x6E
    case DG15 = 0x6F
    case DG16 = 0x70
    case SOD = 0x77
    
    var fileId: [UInt8] {
        switch self {
        case .COM: return [0x01,0x1E]
        case .DG1: return [0x01,0x01]
        case .DG2: return [0x01,0x02]
        case .DG3: return [0x01,0x03]
        case .DG4: return [0x01,0x04]
        case .DG5: return [0x01,0x05]
        case .DG6: return [0x01,0x06]
        case .DG7: return [0x01,0x07]
        case .DG8: return [0x01,0x08]
        case .DG9: return [0x01,0x09]
        case .DG10: return [0x01,0x0A]
        case .DG11: return [0x01,0x0B]
        case .DG12: return [0x01,0x0C]
        case .DG13: return [0x01,0x0D]
        case .DG14: return [0x01,0x0E]
        case .DG15: return [0x01,0x0F]
        case .DG16: return [0x01,0x10]
        case .SOD: return [0x01,0x1D]
        }
    }
    
    var model: DataGroup.Type {
        switch self {
        case .COM: return PassportScanner.COM.self
        case .DG1: return PassportScanner.DG1.self
        case .DG2: return PassportScanner.DG2.self
        case .DG7: return PassportScanner.DG7.self
        case .DG11: return PassportScanner.DG11.self
        case .DG12: return PassportScanner.DG12.self
        case .SOD: return PassportScanner.SOD.self
        default: return PassportScanner.DataGroup.self
        }
    }
}

