import Foundation
import Metal
import simd

// Define a type alias for a vector of three floats, used for acceleration data.
typealias Acceleration = SIMD3<Float>

class GPUDevice {
    static let shared = GPUDevice()
    
    let device: MTLDevice!
    var library: MTLLibrary!
    var vertexFunction: MTLFunction!
    var fragmentFunctions: [MTLFunction] = []
    
    var resolutionBuffer: MTLBuffer!
    var timeBuffer: MTLBuffer!
    var volumeBuffer: MTLBuffer!
    var accelerationBuffer: MTLBuffer!
    var touchedPositionBuffer: MTLBuffer!

    private init() {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        device = defaultDevice
        
        do {
            library = try device.makeDefaultLibrary(bundle: Bundle.main)
            setupVertexAndFragmentFunctions()
            setUpBuffers()
        } catch {
            fatalError("Failed to load Metal library: \(error)")
        }
    }
    
    private func setupVertexAndFragmentFunctions() {
        guard let vertexFunc = library.makeFunction(name: "vertexShader") else {
            fatalError("Vertex function not found")
        }
        vertexFunction = vertexFunc

        let fragmentNames = library.functionNames.filter { $0.hasPrefix("fragment") }
        for name in fragmentNames {
            if let function = library.makeFunction(name: name) {
                fragmentFunctions.append(function)
            }
        }
    }
    
    private func setUpBuffers() {
        resolutionBuffer = makeBuffer(length: MemoryLayout<SIMD2<Float>>.size, options: [])
        timeBuffer = makeBuffer(length: MemoryLayout<Float>.size, options: [])
        volumeBuffer = makeBuffer(length: MemoryLayout<Float>.size, options: [])
        accelerationBuffer = makeBuffer(length: MemoryLayout<Acceleration>.size, options: [])
        touchedPositionBuffer = makeBuffer(length: MemoryLayout<SIMD2<Float>>.size, options: [])
    }
    
    private func makeBuffer(length: Int, options: MTLResourceOptions) -> MTLBuffer {
        guard let buffer = device.makeBuffer(length: length, options: options) else {
            fatalError("Could not create buffer of length \(length)")
        }
        return buffer
    }

    func updateResolution(width: Float, height: Float) {
        var values = [width, height]
        memcpy(resolutionBuffer.contents(), &values, MemoryLayout<Float>.size * 2)
    }
    
    func updateTime(_ time: Float) {
        updateBuffer(time, buffer: timeBuffer)
    }

    func updateVolume(_ volume: Float) {
        updateBuffer(volume, buffer: volumeBuffer)
    }
    
    func updateAcceleration(_ acceleration: Acceleration) {
        updateBuffer(acceleration, buffer: accelerationBuffer)
    }
    
    func updateTouchedPosition(x: Float, y: Float) {
        var values = [x, y]
        memcpy(touchedPositionBuffer.contents(), &values, MemoryLayout<Float>.size * 2)
    }
    
    private func updateBuffer<T>(_ data: T, buffer: MTLBuffer) {
        let pointer = buffer.contents().bindMemory(to: T.self, capacity: 1)
        pointer.pointee = data
    }
}
