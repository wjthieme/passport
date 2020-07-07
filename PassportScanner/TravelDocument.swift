//
//  TravelDocument.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 05/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import Foundation

fileprivate let passportRegexPattern = "^(P[A-Z0-9<]{1})([A-Z<]{3})([A-Z0-9<]{39})([A-Z0-9<]{9})([0-9<]{1})([A-Z<]{3})([0-9]{6})([0-9]{1})([MF<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{14})([0-9<]{1})([0-9<]{1})$"
fileprivate let idRegexPattern = "^([IAC]{1}[A-Z0-9<]{1})([A-Z<]{3})([A-Z0-9<]{9})([0-9<]{1})([A-Z0-9<]{15})([0-9]{6})([0-9]{1})([MF<]{1})([0-9]{6})([0-9]{1})([A-Z<]{3})([A-Z0-9<]{11})([0-9]{1})([A-Z<]{30})$"
fileprivate let licenceRegexPattern = "^(D[A-Z0-9<]{1})([A-Z<]{3})([A-Z0-9<]{25})$"
fileprivate let visaARegexPattern = "^(V[A-Z0-9<]{1})([A-Z<]{3})([A-Z0-9<]{39})([A-Z0-9<]{9})([0-9<]{1})([A-Z<]{3})([0-9]{6})([0-9]{1})([MF<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{16})$"
fileprivate let visaBRegexPattern = "^(V[A-Z0-9<]{1})([A-Z<]{3})([A-Z0-9<]{31})([A-Z0-9<]{9})([0-9<]{1})([A-Z<]{3})([0-9]{6})([0-9]{1})([MF<]{1})([0-9]{6})([0-9]{1})([A-Z0-9<]{8})$"
fileprivate let charValue = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

private let charSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890<")

class TravelDocument: CustomStringConvertible {
    enum Sex: String { case male = "M", female = "F", unspecified = "<" }
    
    private var typeCode: String
    private var names: [String]
    private var issuingCountry: String
    private var documentNumber: String
    private var documentNumberChecksum: String
    private var nationality: String
    private var dob: String
    private var dobChecksum: String
    private var sex: Sex
    private var expiry: String
    private var expiryChecksum: String
    private var personalNumber: String
    private var personalNumberChecksum: String
    private var optional1ForChecksum: String
    private var optional2ForChecksum: String
    private var checksumChecksum: String
    
    init(_ text: String) throws {
        let str = text.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        
        let pRegex = try NSRegularExpression(pattern: passportRegexPattern, options: [])
        let idRegex = try NSRegularExpression(pattern: idRegexPattern, options: [])
        let vARegex = try NSRegularExpression(pattern: visaARegexPattern, options: [])
        let vBRegex = try NSRegularExpression(pattern: visaBRegexPattern, options: [])
        let dRegex = try NSRegularExpression(pattern: licenceRegexPattern, options: [])
        let regex = try NSRegularExpression(pattern: "[^A-Z0-9<]", options: [])
        
        let range = NSRange(location: 0, length: str.count)
        
        guard regex.firstMatch(in: str, options: [], range: range) == nil else { throw NSError(domain: "\(type(of: self))", code: 0, userInfo: nil) }
        
        if let match = pRegex.firstMatch(in: str, options: [], range: range) {
            let groups = match.groups(str)
            typeCode = groups[1]
            issuingCountry = groups[2]
            names = groups[3].components(separatedBy: "<").filter { $0 != "" && $0 != "<" }
            documentNumber = groups[4]
            documentNumberChecksum = groups[5]
            nationality = groups[6]
            dob = groups[7]
            dobChecksum = groups[8]
            sex = Sex(rawValue: groups[9]) ?? .unspecified
            expiry = groups[10]
            expiryChecksum = groups[11]
            personalNumber = groups[12]
            personalNumberChecksum = groups[13]
            checksumChecksum = groups[14]
            optional1ForChecksum = ""
            optional2ForChecksum = ""
        } else if let match = idRegex.firstMatch(in: str, options: [], range: range) {
            let groups = match.groups(str)
            typeCode = groups[1]
            issuingCountry = groups[2]
            documentNumber = groups[3]
            documentNumberChecksum = groups[4]
            optional1ForChecksum = groups[5]
            dob = groups[6]
            dobChecksum = groups[7]
            sex = Sex(rawValue: groups[8]) ?? .unspecified
            expiry = groups[9]
            expiryChecksum = groups[10]
            optional2ForChecksum = groups[11]
            nationality = groups[12]
            checksumChecksum = groups[13]
            personalNumber = ""
            personalNumberChecksum = ""
            names = groups[14].components(separatedBy: "<").filter { $0 != "" && $0 != "<" }
        } else if let match = vARegex.firstMatch(in: str, options: [], range: range) ?? vBRegex.firstMatch(in: str, options: [], range: range) {
            let groups = match.groups(str)
            typeCode = groups[1]
            issuingCountry = groups[2]
            names = groups[3].components(separatedBy: "<").filter { $0 != "" && $0 != "<" }
            documentNumber = groups[4]
            documentNumberChecksum = groups[5]
            nationality = groups[6]
            dob = groups[5]
            dobChecksum = groups[6]
            sex = Sex(rawValue: groups[7]) ?? .unspecified
            expiry = groups[8]
            expiryChecksum = groups[9]
            optional1ForChecksum = groups[10]
            personalNumber = ""
            personalNumberChecksum = ""
            optional2ForChecksum = ""
            checksumChecksum = ""
        } else if let match = dRegex.firstMatch(in: str, options: [], range: range) {
            let groups = match.groups(str)
            typeCode = groups[1]
            issuingCountry = groups[2]
            names = [""]
            documentNumber = ""
            documentNumberChecksum = ""
            nationality = ""
            dob = ""
            dobChecksum = ""
            sex = .unspecified
            expiry = ""
            expiryChecksum = ""
            personalNumber = ""
            personalNumberChecksum = ""
            optional1ForChecksum = ""
            optional2ForChecksum = ""
            checksumChecksum = ""
        } else {
            throw NSError(domain: "\(type(of: self))", code: 1, userInfo: nil)
        }
        guard isValid else { throw NSError(domain: "\(type(of: self))", code: 2, userInfo: nil) }
        
    }
    
    var isValid: Bool {
        if calculateChecksum(documentNumber) != documentNumberChecksum { return false }
        if calculateChecksum(dob) != dobChecksum { return false }
        if calculateChecksum(expiry) != expiryChecksum { return false }
        if calculateChecksum(personalNumber) != personalNumberChecksum { return false }
        
        if checksumChecksum != "" {
            let checkSumStr = "\(documentNumber)\(documentNumberChecksum)\(optional1ForChecksum)\(dob)\(dobChecksum)\(expiry)\(expiryChecksum)\(personalNumber)\(personalNumberChecksum)\(optional2ForChecksum)"
            if calculateChecksum(checkSumStr) != checksumChecksum { return false }
        }
        
        return true
    }
    
    var isExpired: Bool? {
        guard let expiry = expiryDate else { return nil }
        return expiry.timeIntervalSinceNow > 0
    }
    
    private func calculateChecksum(_ str: String) -> String {
        if str == "" { return "" }
        if str.replacingOccurrences(of: "<", with: "") == "" { return "<" }
        var total = 0
        var multiplier = [7, 3, 1]
        for char in str {
            let value = charValue.firstIndex(of: String(char)) ?? 0
            total += value * multiplier[0]
            multiplier.append(multiplier[0])
            multiplier.remove(at: 0)
        }
        return "\(total % 10)"
    }
    
    
    
    
    var mrzKey: String {
        switch typeCode {
        case let str where str.contains("P"):
            return "\(documentNumber)\(documentNumberChecksum)\(dob)\(dobChecksum)\(expiry)\(expiryChecksum)"
        case let str where str.contains("I") || str.contains("A") || str.contains("C"):
            return ""
        case let str where str.contains("D"):
            return ""
        case let str where str.contains("V"):
            return ""
        default:
            return ""
        }
        
    }
    
    #if DEBUG
    
    private func toDate(_ str: String) -> Date? {
        if str.count != 6 { return nil }
        let current = Date()
        let cal = Calendar(identifier: .gregorian)
        
        //TODO: Doesn't work with people older than 50
        guard let yy = Int(str[str.index(str.startIndex, offsetBy: 0)..<str.index(str.startIndex, offsetBy: 2)]) else { return nil }
        guard let dd = Int(str[str.index(str.startIndex, offsetBy: 2)..<str.index(str.startIndex, offsetBy: 4)]) else { return nil }
        guard let mm = Int(str[str.index(str.startIndex, offsetBy: 4)..<str.index(str.startIndex, offsetBy: 6)]) else { return nil }
        let yyy = cal.component(.year, from: current)
        let cc = yyy / 100
        let c1 = cc*100 + yy
        let c2 = (cc+1)*100 + yy
        let c3 = (cc-1)*100 + yy
        guard let yyyy = [c1, c2, c3].max(by: { abs($0 - yyy) > abs($1 - yyy) }) else { return nil }
        
        let date = DateComponents(calendar: cal, year: yyyy, month: mm, day: dd)
        
        
        return cal.date(from: date)
    }
    
    var firstNames: String { return names.dropFirst().joined(separator: " ") }
    var lastName: String { return names[0] }
    var fullName: String { return "\(lastName), \(firstNames)" }
    var dateOfBirth: Date? { return toDate(dob) }
    var expiryDate: Date? { return toDate(expiry) }
    
    
    var description: String {
        var output: [String] = []
        if typeCode.replacingOccurrences(of: "<", with: "") != "" { output.append("Document Type: \(typeCode.replacingOccurrences(of: "<", with: ""))") }
        if documentNumber.replacingOccurrences(of: "<", with: "") != "" { output.append("Document Number: \(documentNumber.replacingOccurrences(of: "<", with: ""))") }
        if firstNames != "" { output.append("Given Names: \(firstNames)") }
        if lastName != "" { output.append("Last Name: \(lastName)") }
        if sex.rawValue != "" {output.append("Sex: \(sex)") }
        if dob != "" {output.append("Date of Birth: \(dob)") }
        if expiry != "" {output.append("Expiry Date: \(expiry)") }
        return "\(output.joined(separator: "\n"))"
    }
    #endif
}


fileprivate extension NSTextCheckingResult {
    func groups(_ str: String) -> [String] {
        var groups: [String] = []
        for n in 0..<numberOfRanges {
            guard let range = Range(range(at: n), in: str) else { continue }
            groups.append(String(str[range]))
        }
        return groups
    }
    
}

