import Foundation
import AVFoundation
import Metal

protocol SessionDelegate {
    func session(_ session: VideoSession, didReceiveVideoTexture texture: MTLTexture)
    func session(_ session: VideoSession, didReceiveAudioVolume value: Float)
}

class VideoSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    static let shared = VideoSession()

    private var session = AVCaptureSession()
    private var videoQueue = DispatchQueue(label: "VideoSession")
    private var audioQueue = DispatchQueue(label: "AudioSession")
    private var textureCache: CVMetalTextureCache?
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let audioDataOutput = AVCaptureAudioDataOutput()

    var delegate: SessionDelegate?
    var videoOrientation: AVCaptureVideoOrientation = .landscapeRight

    private override init() {
        super.init()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        session.beginConfiguration()
        configureVideoInput()
        configureAudioInput()
        configureVideoOutput()
        configureAudioOutput()
        session.commitConfiguration()
    }

    private func configureVideoInput() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Unable to access the camera")
            return
        }
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
    }

    private func configureAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            fatalError("Unable to access the microphone")
            return
        }
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
    }

    private func configureVideoOutput() {
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.connection(with: .video)?.videoOrientation = videoOrientation
        }
    }

    private func configureAudioOutput() {
        audioDataOutput.setSampleBufferDelegate(self, queue: audioQueue)
        if session.canAddOutput(audioDataOutput) {
            session.addOutput(audioDataOutput)
        }
    }

    private func initializeCache() {
        guard let device = MTLCreateSystemDefaultDevice(),
              CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache) == kCVReturnSuccess else {
            fatalError("Unable to initialize texture cache")
        }
    }

    func startSession(viewSize: CGSize) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }
            if granted {
                DispatchQueue.main.async {
                    self.initializeCache()
                    self.session.startRunning()
                }
            } else {
                print("Permission to use camera not granted")
            }
        }
    }

    func endSession() {
        session.stopRunning()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output === videoDataOutput {
            guard let texture = createTexture(from: sampleBuffer) else { return }
            delegate?.session(self, didReceiveVideoTexture: texture)
        } else if output === audioDataOutput {
            guard let channel = connection.audioChannels.first else { return }
            let volume = Float(exp(channel.averagePowerLevel / 20.0))
            delegate?.session(self, didReceiveAudioVolume: volume)
        }
    }

    private func createTexture(from sampleBuffer: CMSampleBuffer) -> MTLTexture? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let textureCache = textureCache else {
            return nil
        }
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        var imageTexture: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, imageBuffer, nil, .bgra8Unorm, width, height, 0, &imageTexture)
        guard let unwrappedImageTexture = imageTexture, let texture = CVMetalTextureGetTexture(unwrappedImageTexture), result == kCVReturnSuccess else {
            return nil
        }
        return texture
    }
}
