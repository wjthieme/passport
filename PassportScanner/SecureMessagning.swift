//
//  SecureMessagning.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation
import CoreNFC

struct ResponseAPDU: CustomStringConvertible {
    let data: [UInt8]
    let sw1: UInt8
    let sw2: UInt8
    
    var description: String { binToHexRep([sw1, sw2] + data, separator: " ") }
}


class SecureMessaging {
    private var ksenc : [UInt8]
    private var ksmac : [UInt8]
    private var ssc : [UInt8]
    
    
    init(ksenc : [UInt8], ksmac : [UInt8], ssc : [UInt8]) {
        self.ksenc = ksenc
        self.ksmac = ksmac
        self.ssc = ssc
    }

    /// Protect the apdu following the doc9303 specification
    func protect(apdu : NFCISO7816APDU ) throws -> NFCISO7816APDU {
    
        let cmdHeader = self.maskClassAndPad(apdu: apdu)
        var do87 : [UInt8] = []
        var do97 : [UInt8] = []
        
        var tmp = "Concatenate CmdHeader"
        if apdu.data != nil {
            tmp += " and DO87"
            do87 = try self.buildD087(apdu: apdu)
        }
        if apdu.expectedResponseLength > 0 {
            tmp += " and DO97"
            do97 = try self.buildD097(apdu: apdu)
        }
        
        let M = cmdHeader + do87 + do97
        
        self.ssc = self.incSSC()

        
        let N = pad(self.ssc + M)
        let CC = try mac(key: self.ksmac, msg: N)

        let do8e = self.buildD08E(mac: CC)
        
        let size = do87.count + do97.count + do8e.count
        var protectedAPDU = [UInt8](cmdHeader[0..<4]) + intToBin(size)
        protectedAPDU += do87 + do97 + do8e + [0x00]
        
//        let data = Data(do87 + do97 + do8e)
//        let newAPDUData : [UInt8] = [UInt8](cmdHeader[0..<4]) + intToBin(data.count) + data + [0x00]
        let newAPDU = NFCISO7816APDU(data:Data(protectedAPDU))!
        
        return newAPDU
    }

    /// Unprotect the APDU following the iso7816 specification
    func unprotect(rapdu : ResponseAPDU) throws -> ResponseAPDU {
        var needCC = false
        var do87 : [UInt8] = []
        var do87Data : [UInt8] = []
        var do99 : [UInt8] = []
        //var do8e : [UInt8] = []
        var offset = 0
        
        // Check for a SM error
        if(rapdu.sw1 != 0x90 || rapdu.sw2 != 0x00) {
            return rapdu
        }
        
        let rapduBin = rapdu.data + [rapdu.sw1, rapdu.sw2]
        
        // DO'87'
        // Mandatory if data is returned, otherwise absent
        if rapduBin[0] == 0x87 {
            let (encDataLength, o) = try asn1Length([UInt8](rapduBin[1...]))
            offset = 1 + o
            
            if rapduBin[offset] != 0x1 {
                throw TagReaderError.d087Malformed
//                raise SecureMessagingException("DO87 malformed, must be 87 L 01 <encdata> : " + binToHexRep(rapdu))
            }
            
            do87 = [UInt8](rapduBin[0 ..< offset + Int(encDataLength)])
            do87Data = [UInt8](rapduBin[offset+1 ..< offset + Int(encDataLength)])
            offset += Int(encDataLength)
            needCC = true
        }
        
        //DO'99'
        // Mandatory, only absent if SM error occurs
        do99 = [UInt8](rapduBin[offset..<offset+4])
        let sw1 = rapduBin[offset+2]
        let sw2 = rapduBin[offset+3]
        offset += 4
        needCC = true
        
        if do99[0] != 0x99 && do99[1] != 0x02 {
            //SM error, return the error code
            return ResponseAPDU(data: [], sw1: sw1, sw2: sw2)
        }
        
        // DO'8E'
        //Mandatory if DO'87' and/or DO'99' is present
        if rapduBin[offset] == 0x8E {
            let ccLength : Int = Int(binToHex(rapduBin[offset+1]))
            let CC = [UInt8](rapduBin[offset+2 ..< offset+2+ccLength])
            // do8e = [UInt8](rapduBin[offset ..< offset+2+ccLength])
            
            // CheckCC
            var tmp = ""
            if do87.count > 0 {
                tmp += " DO'87"
            }
            if do99.count > 0 {
                tmp += " DO'99"
            }
            
            self.ssc = self.incSSC()
            
            let K = pad(self.ssc + do87 + do99)
            
            let CCb = try mac(key: self.ksmac, msg: K)
            
            let res = (CC == CCb)
            
            if !res {
                throw TagReaderError.invalidResponseChecksum
            }
        }
        else if needCC {
            throw TagReaderError.missingMandatoryFields
        }
        
        var data : [UInt8] = []
        if do87Data.count > 0 {
            // There is a payload
            let dec = try DES.tripleDecrypt(key: self.ksenc, message: do87Data, iv: [0,0,0,0,0,0,0,0])
            data = unpad(dec)
        }
        return ResponseAPDU(data: data, sw1: sw1, sw2: sw2)
    }

    private func maskClassAndPad(apdu : NFCISO7816APDU ) -> [UInt8] {
        let res = pad([0x0c, apdu.instructionCode, apdu.p1Parameter, apdu.p2Parameter])
        return res
    }
    
    private func buildD087(apdu : NFCISO7816APDU) throws -> [UInt8] {
        let cipher = try [0x01] + self.padAndEncryptData(apdu)
        let res = try [0x87] + toAsn1Length(cipher.count) + cipher
        return res
    }
    
    private func padAndEncryptData(_ apdu : NFCISO7816APDU) throws -> [UInt8] {
        // Pad the data, encrypt data with KSenc and build DO'87
        let data = [UInt8](apdu.data!)
        let paddedData = pad( data )
        let enc = try DES.tripleEncrypt(key: self.ksenc, message: paddedData, iv: [0,0,0,0,0,0,0,0])
        return enc
    }
    
    private func incSSC() -> [UInt8] {
        let val = binToHex(self.ssc) + 1
        return hexToBin( val )

//        out = binToHex(self.ssc) + 1
//        res = hexToBin(out)
//        return res
    }
    
    private func buildD08E(mac : [UInt8]) -> [UInt8] {
        let res : [UInt8] = [0x8E, UInt8(mac.count)] + mac
        return res
    }

    private func buildD097(apdu : NFCISO7816APDU) throws -> [UInt8] {
        let le = apdu.expectedResponseLength
        var binLe = intToBin(le)
        if (le == 256 || le == 65536) {
            binLe = [0x00] + (le > 256 ? [0x00] : [])
        }
        
        let res : [UInt8] = try [0x97] + toAsn1Length(binLe.count) + binLe
        return res
    }
    
}

