//
//  ViewController.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 05/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreNFC

fileprivate let videoQueue =  DispatchQueue(label: "VideoBufferQueue")
fileprivate let metadataQueue = DispatchQueue(label: "MetadataQueue")
fileprivate let analyzeQueue = DispatchQueue(label: "AnalyzeQueue")

class CameraController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    private var captureSession: AVCaptureSession?
    private var readerSession = TagReaderSession()
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let scannerSquare = UIView()
    
    private var isCapturesSessionBuilt = false
    private var isPaused = false
    private var isAnalyzing = false
//    private var previousBuffer: CVPixelBuffer?
    
    private var xPercentage: CGFloat = 0
    private var yPercentage: CGFloat = 0
    private var screenAspect: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scannerSquare.translatesAutoresizingMaskIntoConstraints = false
        scannerSquare.layer.borderColor = UIColor.white.cgColor
        scannerSquare.layer.borderWidth = 4
        scannerSquare.layer.cornerRadius = 8
        view.addSubview(scannerSquare)
 
        let widthPercentage: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 0.9 : 0.5
        scannerSquare.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthPercentage).isActive = true
        scannerSquare.widthAnchor.constraint(equalTo: scannerSquare.heightAnchor, multiplier: 1.586).isActive = true
        scannerSquare.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scannerSquare.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
        
        isPaused = true
        readerSession.read(with: "NTHFL3BC9896121322506263", dataGroups: [.DG2]) { (groups, error) in
            if let error = error { print(error); return }
            guard let dg2 = groups?.first as? DG2 else { return }
            
            

        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldBuildCaptureSession()
        NotificationCenter.default.addObserver(self, selector: #selector(shouldBuildCaptureSession), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(recycleCaptureSession), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unpauseCaptureSession), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseCaptureSession), name: UIApplication.willResignActiveNotification, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        recycleCaptureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        
        xPercentage = scannerSquare.frame.width / view.frame.width
        yPercentage = scannerSquare.frame.height / view.frame.height
        screenAspect = view.frame.width / view.frame.height

        
    }

    
    @objc private func shouldBuildCaptureSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                granted ? self?.buildCaptureSession() : self?.showAuthorizationAlert()
            }
        }
    }
    
    
    private func buildCaptureSession() {
        defer { unpauseCaptureSession() }
        if isCapturesSessionBuilt { return }
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        captureSession?.addInput(input)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        let bufferOutput = AVCaptureVideoDataOutput()
        captureSession?.addOutput(bufferOutput)
        bufferOutput.setSampleBufferDelegate(self, queue: videoQueue)
        bufferOutput.alwaysDiscardsLateVideoFrames = true
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        
        captureSession?.commitConfiguration()
        isCapturesSessionBuilt = true
    }
    
    @objc private func recycleCaptureSession() {
        pauseCaptureSession()
        previewLayer?.removeFromSuperlayer()
        captureSession = nil
        previewLayer = nil
        captureSession = nil
        isCapturesSessionBuilt = false
    }
    
    @objc private func pauseCaptureSession() {
        captureSession?.stopRunning()
    }
    
    @objc private func unpauseCaptureSession() {
        captureSession?.startRunning()
    }
    
    private func showAuthorizationAlert() {
        let alert = UIAlertController(title: nil, message: "AuthorizationError", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        present(alert, animated: true, completion: nil)
    }




}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
           
        if isPaused { return }
        if isAnalyzing { return }
        isAnalyzing = true
        
        analyzeQueue.async { [weak self] in
            guard let self = self else { return }
            defer { self.isAnalyzing = false }
            let ci = self.preprocessBuffer(buffer)
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(ciImage: ci, options: [:])
            try? handler.perform([request])
                
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            
            let lineWidths = Set([30, 36, 44, 60, 72, 88, 90])
            let candidates = results.map({ $0.topCandidates(5).filter({ lineWidths.contains($0.string.count) }) }).compactMap { $0.first?.string }
            let text = candidates.joined()

            guard let document = try? TravelDocument(text) else { return }

            self.isPaused = true
            self.readDocument(document)

            
        }
    }
    
    
    private func preprocessBuffer(_ buffer: CVPixelBuffer) -> CIImage {
        let image = CIImage(cvImageBuffer: buffer).oriented(.right)
        let imageAspect = image.extent.width / image.extent.height
        
        
        var width: CGFloat
        var height: CGFloat
        if screenAspect > imageAspect {
            width = image.extent.width * xPercentage
            height = width / 1.586
        } else {
            height = image.extent.height * yPercentage
            width = height * 1.586
        }
    
        let x = image.extent.width * 0.5 - width * 0.5
        let y = image.extent.height * 0.5 - height * 0.5
    
        let rect =  CGRect(x: x, y: y, width: width, height: height * 0.3)
        
        return image.cropped(to: rect)
    }
    
}

extension CameraController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if isPaused { return }
        if isAnalyzing { return }
        guard metadataObjects.count > 0 else { return }
        
        for object in metadataObjects {
            guard let object = object as? AVMetadataMachineReadableCodeObject else { continue }
            guard let mrz = object.stringValue else { continue }
            guard let document = try? TravelDocument(mrz) else { continue }
            
            isPaused = true
            
            readDocument(document)
            
        }
    }
}

extension CameraController {
    
    func readDocument(_ document: TravelDocument) {
        print(document.mrzKey)
        if NFCTagReaderSession.readingAvailable(d) {
            readerSession.read(with: document.mrzKey, dataGroups: [.DG2]) { (doc, error) in

                print(error)
            }
        } else {
            showLabel(document.description)
        }
    }
    
    private func showLabel(_ label: String) {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.showLabel(label) }; return}
    
        let alert = UIAlertController(title: nil, message: label, preferredStyle: .actionSheet)
    
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
            self.isPaused = false
        }))
        present(alert, animated: true, completion: nil)
        alert.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint)-> (Bool)  in
            return (one.constant < 0) && (one.secondItem == nil) &&  (one.firstAttribute == .width)
        }.first?.isActive = false
    }
}


