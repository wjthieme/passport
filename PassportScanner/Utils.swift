//
//  Utils.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto

func pad(_ toPad : [UInt8]) -> [UInt8] {
    let size = 8
    let padBlock : [UInt8] = [0x80, 0, 0, 0, 0, 0, 0, 0]
    let left = size - (toPad.count % size)
    return (toPad + [UInt8](padBlock[0 ..< left]))
}

func unpad( _ tounpad : [UInt8]) -> [UInt8] {
    var i = tounpad.count-1
    while tounpad[i] == 0x00 {
        i -= 1
    }
    
    if tounpad[i] == 0x80 {
        return [UInt8](tounpad[0..<i])
    } else {
        // no padding
        return tounpad
    }
}

func mac(key : [UInt8], msg : [UInt8]) throws -> [UInt8] {
    
    let size = msg.count / 8
    var y : [UInt8] = [0,0,0,0,0,0,0,0]
    
    
    for i in 0 ..< size {
        let tmp = [UInt8](msg[i*8 ..< i*8+8])
        y = try DES.encrypt(key: [UInt8](key[0..<8]), message: tmp, iv: y)
    }
    
    let iv : [UInt8] = [0,0,0,0,0,0,0,0]
    let b = try DES.decrypt(key: [UInt8](key[8..<16]), message: y, iv: iv, options:0x0002)
    let a = try DES.encrypt(key: [UInt8](key[0..<8]), message: b, iv: iv, options:0x0002)
    
    return a
}

func intToBin(_ data : Int, pad : Int = 2) -> [UInt8] {
    if pad == 2 {
        let hex = String(format:"%02x", data)
        return hexRepToBin(hex)
    } else {
        let hex = String(format:"%04x", data)
        return hexRepToBin(hex)

    }
}

func hexRepToBin(_ val : String) -> [UInt8] {
    var output : [UInt8] = []
    var x = 0
    while x < val.count {
        if x+2 <= val.count {
            output.append( UInt8(val[x ..< x + 2], radix:16)! )
        } else {
            output.append( UInt8(val[x ..< x+1], radix:16)! )

        }
        x += 2
    }
    return output
}

func toAsn1Length(_ data : Int) throws -> [UInt8] {
    if data <= 0x7F {
        return hexRepToBin(String(format:"%02x", data))
    }
    if data >= 0x80 && data <= 0xFF {
        return [0x81] + hexRepToBin( String(format:"%02x",data))
    }
    if data >= 0x0100 && data <= 0xFFFF { //binToHex("\x01\x00") and data <= binToHex("\xFF\xFF") {
        return [0x82] + hexRepToBin( String(format:"%04x",data))
    }
    
    throw TagReaderError.invalidASN1Value
}


func asn1Length(_ data : [UInt8]) throws -> (Int, Int)  {
    if data[0] <= 0x7F {
        return (Int(binToHex(data[0])), 1)
    }
    if data[0] == 0x81 {
        return (Int(binToHex(data[1])), 2)
    }
    if data[0] == 0x82 {
        let val = binToHex([UInt8](data[1..<3]))
        return (Int(val), 3)
    }
    
    throw TagReaderError.cannotDecodeASN1Length
    
}

func binToInt( _ val: ArraySlice<UInt8> ) -> Int {
    let hexVal = binToInt( [UInt8](val) )
    return hexVal
}

func binToInt( _ val: [UInt8] ) -> Int {
    let hexVal = Int(binToHexRep(val), radix:16)!
    return hexVal
}

func binToHex( _ val: [UInt8] ) -> UInt64 {
    let hexVal = UInt64(binToHexRep(val), radix:16)!
    return hexVal
}

func binToHexRep( _ val : [UInt8], separator: String = "") -> String {
    let str = val.map { String(format:"%02x", $0) }
    return str.joined(separator: separator).uppercased()
}

func hexToBin( _ val : UInt64 ) -> [UInt8] {
    let hexRep = String(format:"%lx", val)
    return hexRepToBin( hexRep)
}

func binToHexRep( _ val : UInt8 ) -> String {
    let string = String(format:"%02x", val ).uppercased()
    return string
}

func binToHex( _ val: UInt8 ) -> Int {
    let hexRep = String(format:"%02X", val)
    return Int(hexRep, radix:16)!
}

func SHA1Hash(_ data: [UInt8]) -> [UInt8] {
    var sha = Insecure.SHA1()
    sha.update(data: data)
    let hash = sha.finalize()
    return Array(hash)
}

func SHA256Hash( _ data: [UInt8] ) -> [UInt8] {
    var sha = SHA256()
    sha.update(data: data)
    let hash = sha.finalize()
    return Array(hash)
}

func xor(_ kifd : [UInt8], _ response_kicc : [UInt8] ) -> [UInt8] {
    var kseed = [UInt8]()
    for i in 0 ..< kifd.count {
        kseed.append( kifd[i] ^ response_kicc[i] )
    }
    return kseed
}

func generateRandomUInt8Array( _ size: Int ) -> [UInt8] {
    var ret : [UInt8] = []
    for _ in 0 ..< size {
        ret.append( UInt8(arc4random_uniform(UInt32(UInt8.max) + 1)) )
    }
    return ret
}
