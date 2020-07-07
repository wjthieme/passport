//
//  TagReaderError.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation

enum TagReaderError: Error {
    case nfcSessionAlreadyInProgress
    case nfcNotSupported
    case nfcReadingError(_ string: String)
    case invalidResponseChecksum
    case missingMandatoryFields
    case d087Malformed
    case invalidASN1Value
    case cannotDecodeASN1Length
    case noResponseFromTag
    case invalidFileId
    case invalidResponse
    case dataConversionError
    
    
    static func decodeTagError(_ sw1: UInt8, _ sw2: UInt8) -> TagReaderError {
        if sw1 == 0x61 {
            return .nfcReadingError("SW2 indicates the number of response bytes still available - (\(binToHexRep(sw2)) bytes still available)")
        } else if sw1 == 0x64 {
            return .nfcReadingError("State of non-volatile memory unchanged (SW2=00, other values are RFU)")
        } else if sw1 == 0x6C {
            return .nfcReadingError("Wrong length Le: SW2 indicates the exact length - (exact length :\(binToHexRep(sw2))")
        }
        
        switch (sw1, sw2) {
        case (0x62, 0x00): return .nfcReadingError("No information given")
        case (0x62, 0x81): return .nfcReadingError("Part of returned data may be corrupted")
        case (0x62, 0x82): return .nfcReadingError("End of file/record reached before reading Le bytes")
        case (0x62, 0x83): return .nfcReadingError("Selected file invalidated")
        case (0x62, 0x84): return .nfcReadingError("FCI not formatted according to ISO7816-4 section 5.1.5")
        case (0x63, 0x81): return .nfcReadingError("File filled up by the last write")
        case (0x63, 0x81): return .nfcReadingError("Card Key not supported")
        case (0x63, 0x83): return .nfcReadingError("Reader Key not supported")
        case (0x63, 0x84): return .nfcReadingError("Plain transmission not supported")
        case (0x63, 0x85): return .nfcReadingError("Secured Transmission not supported")
        case (0x63, 0x86): return .nfcReadingError("Volatile memory not available")
        case (0x63, 0x87): return .nfcReadingError("Non Volatile memory not available")
        case (0x63, 0x88): return .nfcReadingError("Key number not valid")
        case (0x63, 0x89): return .nfcReadingError("Key length is not correct")
        case (0x63, 0x0C): return .nfcReadingError("Counter provided by X (valued from 0 to 15) (exact meaning depending on the command)")
        case (0x65, 0x00): return .nfcReadingError("No information given")
        case (0x65, 0x81): return .nfcReadingError("Memory failure")
        case (0x67, 0x00): return .nfcReadingError("Wrong length")
        case (0x68, 0x00): return .nfcReadingError("No information given")
        case (0x68, 0x81): return .nfcReadingError("Logical channel not supported")
        case (0x68, 0x82): return .nfcReadingError("Secure messaging not supported")
        case (0x69, 0x00): return .nfcReadingError("No information given")
        case (0x69, 0x81): return .nfcReadingError("Command incompatible with file structure")
        case (0x69, 0x82): return .nfcReadingError("Security status not satisfied")
        case (0x69, 0x83): return .nfcReadingError("Authentication method blocked")
        case (0x69, 0x84): return .nfcReadingError("Referenced data invalidated")
        case (0x69, 0x85): return .nfcReadingError("Conditions of use not satisfied")
        case (0x69, 0x86): return .nfcReadingError("Command not allowed (no current EF)")
        case (0x69, 0x87): return .nfcReadingError("Expected SM data objects missing")
        case (0x69, 0x88): return .nfcReadingError("SM data objects incorrect")
        case (0x6A, 0x00): return .nfcReadingError("No information given")
        case (0x6A, 0x80): return .nfcReadingError("Incorrect parameters in the data field")
        case (0x6A, 0x81): return .nfcReadingError("Function not supported")
        case (0x6A, 0x82): return .nfcReadingError("File not found")
        case (0x6A, 0x83): return .nfcReadingError("Record not found")
        case (0x6A, 0x84): return .nfcReadingError("Not enough memory space in the file")
        case (0x6A, 0x85): return .nfcReadingError("Lc inconsistent with TLV structure")
        case (0x6A, 0x86): return .nfcReadingError("Incorrect parameters P1-P2")
        case (0x6A, 0x87): return .nfcReadingError("Lc inconsistent with P1-P2")
        case (0x6A, 0x88): return .nfcReadingError("Referenced data not found")
        case (0x6B, 0x00): return .nfcReadingError("Wrong parameter(s) P1-P2]")
        case (0x6D, 0x00): return .nfcReadingError("Instruction code not supported or invalid")
        case (0x6E, 0x00): return .nfcReadingError("Class not supported")
        case (0x6F, 0x00): return .nfcReadingError("No precise diagnosis")
        default: return .nfcReadingError("Unknown (\(binToHexRep([sw1, sw2])))")
        }
        
    }
    
}
