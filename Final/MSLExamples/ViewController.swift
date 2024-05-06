import UIKit
import MetalKit
import AVFoundation

class ViewController: UIViewController, MTKViewDelegate, SessionDelegate {
    @IBOutlet weak var metalView: MTKView!
    private var shaderButtons: [UIButton] = []
    private let shaderNames = ["shader_day8", "shader_day13", "shader_day39", "shader_day41", "shader_day70", "shader_Ex002"]
    private var pipelineState: MTLRenderPipelineState!
    private var semaphore = DispatchSemaphore(value: 1)
    private var commandQueue: MTLCommandQueue!
    private var cameraTexture: MTLTexture?
    private var grayNoiseSmallTexture: MTLTexture!
    private var rgbaNoiseSmallTexture: MTLTexture!
    private var rgbaNoiseTexture: MTLTexture!
    private var rustyMetalTexture: MTLTexture!
    private var abstract1Texture: MTLTexture!
    private var volumeLevel: Float = 0.0
    private var touched = CGPoint(x: 0.0, y: 0.0)
    private let gpu = GPUDevice.shared
    private let scaleFactor = UIScreen.main.scale
    private let startDate = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initializeMetalComponents()
        VideoSession.shared.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VideoSession.shared.startSession(viewSize: view.bounds.size)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        VideoSession.shared.endSession()
    }

    private func setupUI() {
        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        
        NSLayoutConstraint.activate([
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -10)
        ])
        
        for shaderName in shaderNames {
            let button = UIButton(type: .system)
            button.setTitle(shaderName, for: .normal)
            button.addTarget(self, action: #selector(shaderButtonTapped(_:)), for: .touchUpInside)
            shaderButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }

    private func initializeMetalComponents() {
        metalView.device = gpu.device
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .depth32Float // Only set this if you need a depth buffer
        metalView.colorPixelFormat = .bgra8Unorm
        commandQueue = gpu.device.makeCommandQueue()
        configurePipeline(withShader: "shader_Ex002")
    }


    @objc private func shaderButtonTapped(_ sender: UIButton) {
        guard let buttonIndex = shaderButtons.firstIndex(of: sender) else { return }
        let shaderName = shaderNames[buttonIndex]
        configurePipeline(withShader: shaderName)
    }

    private func configurePipeline(withShader shaderName: String) {
        guard let newFunction = gpu.library?.makeFunction(name: shaderName) else {
            print("Failed to load shader function \(shaderName)")
            return
        }
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = gpu.vertexFunction
        pipelineStateDescriptor.fragmentFunction = newFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        // If using depth attachment, make sure to set this correctly
        if metalView.depthStencilPixelFormat != .invalid {
            pipelineStateDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        }

        do {
            pipelineState = try gpu.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Error creating pipeline state: \(error)")
        }
    }

    func session(_ session: VideoSession, didReceiveVideoTexture texture: MTLTexture) {
        cameraTexture = texture
    }

    func session(_ session: VideoSession, didReceiveAudioVolume volume: Float) {
        volumeLevel = volume
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        gpu.updateResolution(width: Float(size.width), height: Float(size.height))
    }

    func draw(in view: MTKView) {
        _ = semaphore.wait(timeout: .distantFuture)
        guard
            let renderPassDescriptor = metalView.currentRenderPassDescriptor,
            let currentDrawable = metalView.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                semaphore.signal()
                return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setFragmentBuffer(gpu.resolutionBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(gpu.timeBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(gpu.volumeBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentBuffer(gpu.touchedPositionBuffer, offset: 0, index: 3)
        renderEncoder.setFragmentTexture(cameraTexture, index: 0)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

        semaphore.signal()
    }
}
