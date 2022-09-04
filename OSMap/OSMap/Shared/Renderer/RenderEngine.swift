//
//  RenderEngine.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

class RenderEngine: NSObject {
    private weak var mtkView: MTKView?
    private var commandQueue: MTLCommandQueue!

    private var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!

    private var renderUnits = [RenderUnit]()

    private override init() {
        super.init()
    }

    init(mtkView: MTKView) {
        super.init()

        self.mtkView = mtkView

        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        guard
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Fatal error: cannot create Queue")
        }
        self.commandQueue = commandQueue

        self.mtkView?.device = device

        self.mtkView?.clearColor = MTLClearColor(red: 1.0,
                                             green: 1.0,
                                             blue: 1.0,
                                             alpha: 1.0)

        self.mtkView?.delegate = self
    }
}

extension RenderEngine {
    func addPrimitive(_ primitive: Primitive) {
        if let mtkView = mtkView {
            let renderUnit = RenderUnit(primitive: primitive, mtkView: mtkView)
            renderUnits.append(renderUnit)
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

        renderUnits.forEach {renderUnit in
            renderEncoder.setRenderPipelineState(renderUnit.pipelineState)

            renderEncoder.setVertexBuffer(renderUnit.vertBuffer, offset: 0, index: 0)

            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: 6,
                                                indexType: .uint16,
                                                indexBuffer: renderUnit.indexBuffer,
                                                indexBufferOffset: 0)
        }

        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
