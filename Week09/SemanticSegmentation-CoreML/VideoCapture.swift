//
//  VideoCapture.swift
//  Awesome ML
//
//  Created by Eugene Bokhan on 3/13/18.
//  Updated by Doyoung Gwak on 03/07/2018.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import UIKit
import AVFoundation
import CoreVideo

public protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoSampleBuffer: CMSampleBuffer)
}

public class VideoCapture: NSObject {
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureDelegate?
    public var fps = 15

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.yourdomain.camera-queue")

    var videoTextureCache: CVMetalTextureCache?

    public func setUp(sessionPreset: AVCaptureSession.Preset = .vga640x480, completion: @escaping (Bool) -> Void) {
        self.setUpCamera(sessionPreset: sessionPreset, position: .back, completion: completion)
    }

    // Change this from private to public to make it accessible
    public func setUpCamera(sessionPreset: AVCaptureSession.Preset, position: AVCaptureDevice.Position? = .back, completion: @escaping (_ success: Bool) -> Void) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        
        let device: AVCaptureDevice?
        if let position = position {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        } else {
            device = AVCaptureDevice.default(for: .video)
        }
        
        guard let captureDevice = device, let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error: no video devices available or could not create video input")
            completion(false)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let settings: [String: Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        videoOutput.connection(with: .video)?.videoOrientation = .portrait

        captureSession.commitConfiguration()

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)

        completion(true)
    }

    public func start() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    public func makePreview() -> AVCaptureVideoPreviewLayer? {
        if let previewLayer = self.previewLayer {
            return previewLayer
        } else {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspect
            previewLayer.connection?.videoOrientation = .portrait
            self.previewLayer = previewLayer
            return previewLayer
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.videoCapture(self, didCaptureVideoSampleBuffer: sampleBuffer)
    }
}
