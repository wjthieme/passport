//
//  ViewController.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 05/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import UIKit
import QKMRZScanner
import NFCPassportReader

fileprivate let videoQueue =  DispatchQueue(label: "VideoBufferQueue")
fileprivate let metadataQueue = DispatchQueue(label: "MetadataQueue")
fileprivate let analyzeQueue = DispatchQueue(label: "AnalyzeQueue")

class CameraController: UIViewController, QKMRZScannerViewDelegate {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    private let mrzScannerView = QKMRZScannerView()
    private let passportReader = PassportReader()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mrzScannerView.delegate = self
        mrzScannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mrzScannerView)
        mrzScannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mrzScannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mrzScannerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mrzScannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mrzScannerView.startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mrzScannerView.stopScanning()
    }
    
    

    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYMMdd"

        guard let dateOfBirth = scanResult.birthDate else { mrzScannerView.startScanning(); return }
        guard let dateOfExpiry = scanResult.expiryDate else { mrzScannerView.startScanning(); return }
        
        let doc = scanResult.documentNumber + calcCheckSum(scanResult.documentNumber)
        let dob = formatter.string(from: dateOfBirth) + calcCheckSum(formatter.string(from: dateOfBirth))
        let exp = formatter.string(from: dateOfExpiry) + calcCheckSum(formatter.string(from: dateOfExpiry))
        passportReader.readPassport(mrzKey: doc + dob + exp, tags: [.DG1, .DG2]) { (model, error) in
            DispatchQueue.main.async {
                if let error = error { print(error); self.mrzScannerView.startScanning(); return }
                guard let model = model else { self.mrzScannerView.startScanning(); return }
                let controller = DisplayController(name: "\(model.firstName) \(model.lastName)", dob: model.dateOfBirth, image: model.passportImage!)
                controller.dismissAction = {
                    self.mrzScannerView.startScanning()
                }
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    
    private func calcCheckSum( _ checkString : String ) -> String {
        let characterDict  = ["0" : "0", "1" : "1", "2" : "2", "3" : "3", "4" : "4", "5" : "5", "6" : "6", "7" : "7", "8" : "8", "9" : "9", "<" : "0", " " : "0", "A" : "10", "B" : "11", "C" : "12", "D" : "13", "E" : "14", "F" : "15", "G" : "16", "H" : "17", "I" : "18", "J" : "19", "K" : "20", "L" : "21", "M" : "22", "N" : "23", "O" : "24", "P" : "25", "Q" : "26", "R" : "27", "S" : "28","T" : "29", "U" : "30", "V" : "31", "W" : "32", "X" : "33", "Y" : "34", "Z" : "35"]
        
        var sum = 0
        var m = 0
        let multipliers : [Int] = [7, 3, 1]
        for c in checkString {
            guard let lookup = characterDict["\(c)"],
                let number = Int(lookup) else { return "0" }
            let product = number * multipliers[m]
            sum += product
            m = (m+1) % 3
        }
        
        return String(sum % 10)
    }

}


