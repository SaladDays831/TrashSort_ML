//
//  ViewController.swift
//  TrashSort
//
//  Created by Danil Kurilo on 26.02.2020.
//  Copyright © 2020 Danil Kurilo. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var camView: UIView!
    @IBOutlet weak var materialLabel: UILabel!
    @IBOutlet weak var predictionLabel: UILabel!
    
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var dataOutput: AVCaptureVideoDataOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createInput()
        createOutput()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        createPreviewLayer()
    }
    
    
    func createInput() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.startRunning()
    }
    
    func createPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = camView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        camView.layer.addSublayer(previewLayer)
    }
    
    func createOutput() {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        guard let model = try? VNCoreMLModel(for: trashNet().model) else {return}
        let request = VNCoreMLRequest(model: model) { (result, error) in
            if error != nil {
                print("Request error: ", error ?? "Something bad happened, and we don't know what")
                return
            }
            guard let results = result.results as? [VNClassificationObservation] else {return}
            guard let first = results.first else {return}
            self.updateLabels(material: first.identifier, confidence: first.confidence)
        }
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        } catch {
            print(error)
        }
        
    }
    
    
    func updateLabels(material: String, confidence: Float) {
        DispatchQueue.main.async {
            self.materialLabel.text = material
            self.predictionLabel.text = String(confidence)
        }
    }

    
    
    
    

}

