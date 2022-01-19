//
//  ViewController.swift
//  ScanPaymentCard
//
//  Created by Caroline LaDouce on 1/18/22.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {

    private let captureSession = AVCaptureSession()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        self.addCameraInput()
        self.addPreviewLayer()
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
    
    
}

