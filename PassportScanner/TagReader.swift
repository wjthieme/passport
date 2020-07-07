//
//  TagReader.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 06/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation
import CoreNFC

fileprivate var callbackQueue = DispatchQueue(label: "callbackQueue")
fileprivate let readingQueue = DispatchQueue(label: "readingQueue")

class TagReaderSession: NSObject {
    
    private var session: NFCTagReaderSession?
    private var tag: NFCISO7816Tag?
    private var completion: (([DataGroup]?, Error?) -> Void)?
    private var isRunning: Bool { return completion != nil  }
    private var key: String = ""
    private var tagError: Error?
    private var dataGroupsToRead: [TagDataGroup] = []
    private var completed = false
//    private var success: 
    
    func read(with mrzkey: String, dataGroups: [TagDataGroup], done: @escaping (([DataGroup]?, Error?) -> Void)) {
        if isRunning { done(nil, TagReaderError.nfcSessionAlreadyInProgress); return }
        completion = { d, e in DispatchQueue.main.async { done(d, e) }; self.completion = nil }
        guard NFCTagReaderSession.readingAvailable else { completion?(nil, TagReaderError.nfcNotSupported); return }
        dataGroupsToRead = dataGroups
        key = mrzkey
        
        session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: callbackQueue)
        session?.begin()
    }
}

extension TagReaderSession: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if completed { completed = false; return }
        let err = tagError ?? error
        completion?(nil, err)
        tagError = nil
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let t = tags.first(where: { if case NFCTag.iso7816(_) = $0 { return true } else { return false } }) else { return }
        guard case NFCTag.iso7816(let tag) = t else { return }
//        session.connect
        session.connect(to: t) { [weak self] error in
            guard let self = self else { return }
            do {
                if let error = error { throw error }
                self.startReadingSequence(tag: tag)
            } catch {
                self.tagError = error
                session.invalidate()
            }
        }
    }
    
    private func startReadingSequence(tag: NFCISO7816Tag) {
        readingQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let (kenc, kmac) = try self.getAccessKeysFromMRZKey()
                let rnd_icc = try self.send(.getChallenge, to: tag).data
                let (cmd_data, rnd_ifd, kifd) = try self.authentication(rnd_icc: rnd_icc, kenc: kenc, kmac: kmac)
                let auth = try self.send(.doAuthentication(cmd_data), to: tag).data
                let (Kenc, Kmac, ssc) = try self.sessionKeys(data: auth, ksenc: kenc, kifd: kifd, rnd_icc: rnd_icc, rnd_ifd: rnd_ifd)
                let security = SecureMessaging(ksenc: Kenc, ksmac: Kmac, ssc: ssc)
                let dgs = try self.dataGroupsToRead.map { try self.selectFileAndRead($0, from: tag, security: security) }
                
                self.completion?(dgs, nil)
                self.completed = true
                self.session?.invalidate()
            } catch {
                self.tagError = error
                self.session?.invalidate()
            }
        }
    }
    
    private func updateStatusMessage(_ str: String) {
        session?.alertMessage = str
    }
}

extension TagReaderSession {
    @discardableResult private func send(_ command: TagCommand, to tag: NFCISO7816Tag, security: SecureMessaging? = nil) throws -> ResponseAPDU {
        let cmd = (try security?.protect(apdu: command.cmd)) ?? command.cmd
        
        print("Sending: \(command)")
        
        var response: ResponseAPDU?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        tag.sendCommand(apdu: cmd) { (data, sw1, sw2, err) in
            error = err
            response = ResponseAPDU(data: [UInt8](data), sw1: sw1, sw2: sw2)
            print("Received: \(response!)")
            semaphore.signal()
        }
        let _ = semaphore.wait(timeout: .now() + 5)
        
        if let error = error { throw error }
        guard let radpu = response else { throw TagReaderError.noResponseFromTag }
        
        let result = (try security?.unprotect(rapdu: radpu)) ?? radpu
        guard result.sw1 == 0x90 && result.sw2 == 0x00 else { throw TagReaderError.decodeTagError(result.sw1, result.sw2) }
        
        return result
    }
    
    
    private func selectFileAndRead(_ dataGroup: TagDataGroup, from tag: NFCISO7816Tag, security: SecureMessaging) throws -> DataGroup {
        try send(.selectFile(dataGroup), to: tag, security: security)
        let response = try send(.readHeader, to: tag, security: security)
        
        var leftToRead = 0
        let (len, o) = try asn1Length([UInt8](response.data[1..<4]))
        
        leftToRead = Int(len)
        let offset = o + 1
        
        let header = [UInt8](response.data[..<offset])
        
        let data = try readBinaryData(header, leftToRead: leftToRead, amountRead: offset, tag: tag, security: security)
        let model = try dataGroup.model.init(data)
        
        return model
    }
    
    private func readBinaryData(_ header: [UInt8], leftToRead: Int, amountRead : Int, tag: NFCISO7816Tag, security: SecureMessaging) throws -> [UInt8] {
        let readAmount = min(leftToRead, 255)
//        var readAmount = 256
//        if leftToRead < 256 { readAmount = leftToRead }
        
        let offset = intToBin(amountRead, pad:4)
        
        let response = try send(.readFile(offset: offset, readAmount: UInt8(readAmount)), to: tag, security: security)
        let data = header + response.data
        
        let remaining = leftToRead - response.data.count
        
        if remaining > 0 {
            return try readBinaryData(data, leftToRead: remaining, amountRead: amountRead + response.data.count, tag: tag, security: security)
        } else {
            return data
        }
    }
    

}

extension TagReaderSession {
    
    private func getAccessKeysFromMRZKey() throws -> (ksenc: [UInt8], ksmac: [UInt8]) {
        guard let data = key.data(using:.utf8) else { throw TagReaderError.dataConversionError }
        let hash = SHA1Hash([UInt8](data))
        let subHash = Array(hash[0..<16])
        let kseed = Array(subHash)
        
        let kenc = keyDerivation(kseed, c: [0,0,0,1])
        let kmac = keyDerivation(kseed, c: [0,0,0,2])
    
        return (kenc, kmac)
    }
    
    
    private func keyDerivation(_ kseed : [UInt8], c: [UInt8] ) -> [UInt8] {
        let d = kseed + c
        let h = SHA1Hash(d)
        
        var Ka = Array(h[0..<8])
        var Kb = Array(h[8..<16])
        
        Ka = DESParity(Ka)
        Kb = DESParity(Kb)

        return Ka+Kb
    }
    
    private func DESParity(_ data : [UInt8]) -> [UInt8] {
        var adjusted = [UInt8]()
        for x in data {
            let y = x & 0xfe
            var parity :UInt8 = 0
            for z in 0 ..< 8 {
                parity += y >> z & 1
            }
            
            let s = y + (parity % 2 == 0 ? 1 : 0)
            
            adjusted.append(s)
        }
        return adjusted
    }
    
    
    private func authentication(rnd_icc : [UInt8], kenc: [UInt8], kmac: [UInt8]) throws -> (cmd_data: [UInt8], rnd_ifd: [UInt8], kifd: [UInt8]) {
        let rnd_ifd = generateRandomUInt8Array(8)
        let kifd = generateRandomUInt8Array(16)
        
        let s = rnd_ifd + rnd_icc + kifd
        
        let eifd = try DES.tripleEncrypt(key: kenc, message: s, iv: [0,0,0,0,0,0,0,0])
        
        let mifd = try mac(key: kmac, msg: pad(eifd))
        
        let cmd_data = eifd + mifd
        
        return (cmd_data, rnd_ifd, kifd)
    }
    
    private func sessionKeys(data : [UInt8], ksenc: [UInt8], kifd: [UInt8], rnd_icc: [UInt8], rnd_ifd: [UInt8]) throws -> ([UInt8], [UInt8], [UInt8]) {
        let response = try DES.tripleDecrypt(key: ksenc, message: [UInt8](data[0..<32]), iv: [0,0,0,0,0,0,0,0])

        let response_kicc = [UInt8](response[16..<32])
        let Kseed = xor(kifd, response_kicc)
        
        
        let KSenc = keyDerivation(Kseed, c: [0,0,0,1])
        let KSmac = keyDerivation(Kseed, c: [0,0,0,2])
        
        
        let ssc = [UInt8](rnd_icc.suffix(4) + rnd_ifd.suffix(4))
        return (KSenc, KSmac, ssc)
    }
}

