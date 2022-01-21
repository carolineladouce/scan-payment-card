//
//  ViewController.swift
//  ScanPaymentCard
//
//  Created by Caroline LaDouce on 1/18/22.
//

import UIKit
import AVFoundation
import Vision

class MainViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let captureSession = AVCaptureSession()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private let requestHandler = VNSequenceRequestHandler()
    
    private var rectangleDrawing: CAShapeLayer?
    
    private var paymentCardRectangleObservation: VNRectangleObservation?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        self.addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.captureSession.startRunning()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.bounds
    }
    
    
    private func addCameraInput() {
        let device = AVCaptureDevice.default(for: .video)!
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    
    private func addPreviewLayer() {
        self.view.layer.addSublayer(self.previewLayer)
    }
    
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
        
        guard let connection = self.videoOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("Unable to get image from sample buffer")
            return
        }
        
        print("Image recieved from frame")
        
        DispatchQueue.main.async {
            self.rectangleDrawing?.removeFromSuperlayer()
        }
        
        if let paymentCardRectangleObservation = self.paymentCardRectangleObservation {
            self.handleObservedPaymentCard(paymentCardRectangleObservation, in: frame)
        } else if let paymentCardRectangleObservation = self.detectPaymentCard(frame: frame) {
            self.paymentCardRectangleObservation = paymentCardRectangleObservation
        }
    }
    
    
    private func detectPaymentCard(frame: CVImageBuffer) -> VNRectangleObservation? {
        let rectangleDetectionRequest = VNDetectRectanglesRequest()
        let paymentCardAspectRatio: Float = 85.60/53.98
        rectangleDetectionRequest.minimumAspectRatio = paymentCardAspectRatio * 0.95
        rectangleDetectionRequest.maximumAspectRatio = paymentCardAspectRatio * 1.10
        
        let textDetectionRequest = VNDetectTextRectanglesRequest()
        
        try? self.requestHandler.perform([rectangleDetectionRequest, textDetectionRequest], on: frame)
        
        guard let rectangle = (rectangleDetectionRequest.results as? [VNRectangleObservation])?.first,
              let text  = (textDetectionRequest.results as? [VNTextObservation])?.first,
              rectangle.boundingBox.contains(text.boundingBox) else {
                  // No payment card rectangle detected
                  print("No payment card rectangle detected")
                  return nil
              }
        
        print("PAYMENT CARD RECTANGLE DETECTED")
        return rectangle
    }
    
    
    private func createRectangleDrawing(_ rectangleObservation: VNRectangleObservation) -> CAShapeLayer {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewLayer.frame.height)
        let scale = CGAffineTransform.identity.scaledBy(x: self.previewLayer.frame.width, y: self.previewLayer.frame.height)
        let rectangleOnScreen = rectangleObservation.boundingBox.applying(scale).applying(transform)
        let boundingBoxPath = CGPath(rect: rectangleOnScreen, transform: nil)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = boundingBoxPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = 5
        shapeLayer.borderWidth = 5
        return shapeLayer
    }
    
    
    private func trackPaymentCard(for observation: VNRectangleObservation, in frame: CVImageBuffer) -> VNRectangleObservation? {
        let request = VNTrackRectangleRequest(rectangleObservation: observation)
        request.trackingLevel = .fast
        
        try? self.requestHandler.perform([request], on: frame)
        
        guard let trackedRectangle = (request.results as? [VNRectangleObservation])?.first else {
            return nil
        }
        return trackedRectangle
    }
    
    
    private func handleObservedPaymentCard(_ observation: VNRectangleObservation, in frame: CVImageBuffer) {
        if let trackedPaymentCardRectangle = self.trackPaymentCard(for: observation, in: frame) {
            DispatchQueue.main.async {
                self.rectangleDrawing = self.createRectangleDrawing(trackedPaymentCardRectangle)
                self.view.layer.addSublayer(self.rectangleDrawing!)
            }
        } else {
            self.paymentCardRectangleObservation = nil
        }
    }
    
    
    private func extractPaymentCardNumber(frame: CVImageBuffer, rectangle: VNRectangleObservation) -> String? {
        let cardPositionInImage = VNImageRectForNormalizedRect(rectangle.boundingBox, CVPixelBufferGetWidth(frame), CVPixelBufferGetHeight(frame))
        let ciImage = CIImage(cvImageBuffer: frame)
        let croppedImage = ciImage.cropped(to: cardPositionInImage)
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let stillImageRequestHandler = VNImageRequestHandler(ciImage: croppedImage, options: [:])
        try? stillImageRequestHandler.perform([request])
        
        guard let texts = request.results as? [VNRecognizedTextObservation], texts.count > 0 else {
            // No text detected
            return nil
        }
        
        let digitsRecognized = texts
            .flatMap({ $0.topCandidates(10).map({ $0.string }) })
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0)) })
        
        let _16digits = digitsRecognized.first(where: { $0.count == 16})
        let has16Digits = _16digits != nil
        
        let _4digits = digitsRecognized.filter({ $0.count == 4 })
        let has4sections4digits = _4digits.count == 4
        
        let digits = _16digits ?? _4digits.joined()
        let digitsIsValid = (has16Digits || has4sections4digits) &&
        self.checkDigits(digits)
        return digitsIsValid ? digits : nil
    }
    
    
    private func checkDigits(_ digits: String) -> Bool {
        guard digits.count == 16,
              CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: digits)) else {
                  return false
              }
        
        var digits = digits
        let checksum = digits.removeLast()
        
        let sum = digits.reversed()
            .enumerated()
            .map({ (index, element) -> Int in
                
                if (index % 2) == 0 {
                    let doubled = Int(String(element))!*2
                    return doubled > 9
                    ? Int(String(String(doubled).first!))! + Int(String(String(doubled).last!))! : doubled
                } else {
                    return Int(String(element))!
                }
            })
            .reduce(0, { (res, next) in res + next })
        let checkDigitCalc = (sum * 9) % 10
        return Int(String(checksum))! == checkDigitCalc
        
    }
    
    
    
}

