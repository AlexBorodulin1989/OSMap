//
//  Renderer.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!

    lazy var frame: Frame = {
        Frame(device: Self.device)
    }()

    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Self.device = device
        Self.commandQueue = commandQueue
        metalView.device = device

        super.init()

        self.addPipeline(metalView: metalView)

        metalView.clearColor = MTLClearColor(red: 1.0,
                                             green: 1.0,
                                             blue: 0.8,
                                             alpha: 1.0)
        metalView.delegate = self
    }
}

extension Renderer {
    func addPipeline(metalView: MTKView) {
        let library = Self.device.makeDefaultLibrary()
        Self.library = library
        let vertexFunction = library?.makeFunction(name: "map_vertex")
        let fragmentFunction = library?.makeFunction(name: "map_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        do {
            pipelineState = try Self.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize
    ) {
    }

    func draw(in view: MTKView) {
        guard
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        renderEncoder.setVertexBuffer(frame.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(frame.indexBuffer, offset: 0, index: 1)
        renderEncoder.drawPrimitives(type: .triangle,
                                     vertexStart: 0, vertexCount: frame.indices.count)

        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
