//
//  RenderEngine.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

class RenderEngine: NSObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!

    private var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!

    lazy var frame: Frame = {
        Frame(device: device)
    }()

    private override init() {
        super.init()
    }

    init(metalView: MTKView) {
        super.init()

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }

        self.device = device
        self.commandQueue = commandQueue
        metalView.device = device

        self.addPipeline(metalView: metalView)

        metalView.clearColor = MTLClearColor(red: 0.9,
                                             green: 0.9,
                                             blue: 0.9,
                                             alpha: 1.0)
        metalView.delegate = self
    }
}

extension RenderEngine {
    func addPipeline(metalView: MTKView) {
        library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "map_vertex")
        let fragmentFunction = library?.makeFunction(name: "map_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = frame.vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}

extension RenderEngine: MTKViewDelegate {
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize
    ) {
    }

    func draw(in view: MTKView) {
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setVertexBuffer(frame.vertexBuffer, offset: 0, index: 0)

        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: frame.indices.count,
                                            indexType: .uint16,
                                            indexBuffer: frame.indexBuffer,
                                            indexBufferOffset: 0)

        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
