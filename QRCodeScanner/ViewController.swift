//
//  ViewController.swift
//  QRCodeScanner
//
//  Created by Boominadha Prakash on 21/04/17.
//  Copyright © 2017 Boomi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var qrScanningView: UIView!
    @IBOutlet weak var qrScanningButton: UIButton!
    var captureSession:AVCaptureSession!
    var videoPreviewLayer:AVCaptureVideoPreviewLayer!
    var audioPlayer:AVAudioPlayer!
    @IBOutlet weak var viewPreview: UIView!
    @IBOutlet weak var scannedQrCode: UILabel!
    var readingStarted:Bool!
    var strScannedQRCode:NSString!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.scannedQrCode.isHidden = true
        self.qrScanningView.isHidden = true
        readingStarted = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startQRScanningSelected(_ sender: Any) {
        
        if !(self.readingStarted)
        {
            if(self.startReading())
            {
                self.qrScanningView.isHidden = false
                self.qrScanningButton.setTitle("Stop Scanning", for: UIControlState.normal)
            }
        }
        else
        {
            self.captureSession.stopRunning()
            self.captureSession = nil
            self.videoPreviewLayer.removeFromSuperlayer()
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ViewController.stopReading), object: nil)
            self.qrScanningButton.setTitle("Start Scanning", for: .normal)
        }
    }
    
    func startReading() -> Bool
    {
        self.strScannedQRCode = nil
        let captureDevice:AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        do {
            let input:AVCaptureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            self.captureSession = AVCaptureSession()
            self.captureSession.addInput(input)
            let capturedMetadataOutput:AVCaptureMetadataOutput = AVCaptureMetadataOutput()
            self.captureSession.addOutput(capturedMetadataOutput)
            let dispatchQueue = DispatchQueue(label: "myQueue")
            capturedMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
            capturedMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            let orientation:UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            switch(orientation)
            {
            case UIInterfaceOrientation.portrait:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                break;
            case UIInterfaceOrientation.portraitUpsideDown:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                break;
            case UIInterfaceOrientation.landscapeLeft:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                break;
            case UIInterfaceOrientation.landscapeRight:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                break;
            default:
                break;
            }
            self.videoPreviewLayer.frame = self.viewPreview.layer.bounds
            self.viewPreview.layer.addSublayer(self.videoPreviewLayer)
            self.captureSession.startRunning()
            
        } catch{
            print("Error occurred when trying to get camera")
        }
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if((self.videoPreviewLayer) != nil)
        {
            let orientation = UIApplication.shared.statusBarOrientation
            switch(orientation)
            {
            case UIInterfaceOrientation.portrait:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                break;
            case UIInterfaceOrientation.portraitUpsideDown:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                break;
            case UIInterfaceOrientation.landscapeLeft:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                break;
            case UIInterfaceOrientation.landscapeRight:
                self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                break;
            default:
                break;
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if (metadataObjects != nil && metadataObjects.count > 0)
        {
            let metadataobj:NSArray = metadataObjects as NSArray
            let metadataObjreadable: AVMetadataMachineReadableCodeObject = metadataobj.object(at: 0) as! AVMetadataMachineReadableCodeObject
            let metastringvalue = metadataObjreadable.stringValue

            if(metadataObjreadable.type == AVMetadataObjectTypeQRCode)
            {
                self.readingStarted = false
                self.performSelector(onMainThread: #selector(ViewController.stopReading), with: nil, waitUntilDone: false)
                self.performSelector(onMainThread: #selector(ViewController.checkScannedQRCodeWith(qrcode:)), with: metastringvalue!, waitUntilDone: false)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ViewController.stopReading), object: nil)
            }
            else
            {
                
            }
        }
    }
    
    func stopReading()
    {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ViewController.stopReading), object: nil)
        
        if(self.readingStarted == true)
        {
            let iOSVersion = Float(UIDevice.current.systemVersion)
            if iOSVersion! < 8.0
            {
                let alert = UIAlertView(title: "Failed", message: "Failed to scan QR Code", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
            else
            {
                let alert:UIAlertController = UIAlertController(title: "Failed", message: "Failed to scan QR Code", preferredStyle: .alert)
                let noButton:UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                    self.dismiss(animated: true, completion: nil)
                })
                alert.addAction(noButton)
                self.present(alert, animated: true, completion: nil)
            }
        }
        self.videoPreviewLayer.removeFromSuperlayer()
        self.qrScanningButton.setTitle("Start Scanning", for: .normal)
        self.captureSession.stopRunning()
        self.captureSession = nil
        self.qrScanningView.isHidden = true
    }
    
    func checkScannedQRCodeWith(qrcode:String)
    {
        self.qrScanningView.isHidden = true
        self.scannedQrCode.isHidden = false
        print("QRcode value:\(qrcode)")
        self.scannedQrCode.text = qrcode as String
    }


}

