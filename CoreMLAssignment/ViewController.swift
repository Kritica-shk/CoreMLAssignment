//
//  ViewController.swift
//  CoreMLAssignment
//
//  Created by EKbana on 30/09/2022.
//

import UIKit
import Vision
import AVKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var objectLabel: UILabel!
    @IBOutlet weak var belowView: UIView!
    
    var model = Resnet50().model
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //camera
        let captureSession = AVCaptureSession()
        
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.addSubview(belowView)
        
        belowView.clipsToBounds = true
        belowView.layer.cornerRadius = 15.0
        belowView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: model) else { return }
        let request = VNCoreMLRequest(model: model) {
            (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            var name: String = firstObservation.identifier
            var acc = Int(firstObservation.confidence * 100)
            
            DispatchQueue.main.async {
                self.objectLabel.text = name
                self.accuracyLabel.text = "Accuracy: \(acc)%"
            }
            
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}

