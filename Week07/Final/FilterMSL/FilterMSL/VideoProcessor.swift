//
//  VideoProcessor.swift
//  FilterMSL
//
//  Created by 陈逸安 on 4/29/24.
//

import Metal
import MetalKit
import CoreVideo

class VideoProcessor: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var textureCache: CVMetalTextureCache!
    weak var metalView: MTKView?

    override init() {
        super.init()
        device = MTLCreateSystemDefaultDevice()
        setupMetal()
        setupPipeline()
        createTextureCache()
    }

    private func setupMetal() {
        guard let queue = device.makeCommandQueue() else {
            fatalError("Unable to create Metal command queue")
        }
        commandQueue = queue
    }

    private func setupPipeline() {
        guard let defaultLibrary = device.makeDefaultLibrary(),
              let vertexFunction = defaultLibrary.makeFunction(name: "basic_vertex"),
              let fragmentFunction = defaultLibrary.makeFunction(name: "shader_day70") else {
            fatalError("Failed to load functions from default library")
        }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            fatalError("Failed to create pipeline state, error: \(error)")
        }
    }

    private func createTextureCache() {
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess else {
            fatalError("Unable to create texture cache")
        }
    }

    func setupTargetView(_ view: MTKView) {
        self.metalView = view
        view.device = device
        view.delegate = self
        view.framebufferOnly = false
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes if needed
    }

    func processFrame(_ imageBuffer: CVImageBuffer) {
        // Implement the image processing using Metal textures and draw to the view
    }
}
