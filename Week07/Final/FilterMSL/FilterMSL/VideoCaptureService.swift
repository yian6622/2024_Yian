//
//  VideoCaptureService.swift
//  FilterMSL
//
//  Created by 陈逸安 on 4/29/24.
//

import AVFoundation

class VideoCaptureService: NSObject {
    var captureSession: AVCaptureSession?
    let videoOutput = AVCaptureVideoDataOutput()
    var videoProcessor: VideoProcessor?

    override init() {
        super.init()
        self.setupCaptureSession()
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high // Or any other preset that suits your needs

        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession?.canAddInput(videoInput) == true else {
            print("Failed to set up video device input")
            return
        }

        captureSession?.addInput(videoInput)

        // Configure video output
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        guard captureSession?.canAddOutput(videoOutput) == true else {
            print("Failed to set up video output")
            return
        }

        captureSession?.addOutput(videoOutput)
        videoOutput.connection(with: .video)?.videoRotationAngle = 0
    }



    func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            self.captureSession?.startRunning()
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.captureSession?.startRunning()
                }
            }
        default:
            print("Access denied")
            return
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
    }
}

extension VideoCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoProcessor = videoProcessor,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer")
            return
        }
        // Ensure the image buffer is in the expected format
        if CVPixelBufferGetPixelFormatType(imageBuffer) == kCVPixelFormatType_32BGRA {
            videoProcessor.processFrame(imageBuffer)
        } else {
            print("Unexpected image buffer format")
        }
    }
}
