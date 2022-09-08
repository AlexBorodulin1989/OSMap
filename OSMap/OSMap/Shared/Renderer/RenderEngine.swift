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

    private var renderGroups = [String: RenderGroup]()

    var timer: Float = 0

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
            let key = String(describing: type(of: primitive.self))

            let renderUnit = RenderUnit(primitive: primitive, mtkView: mtkView)
            if let renderGroup = renderGroups[key] {
                renderGroup.addRenderUnit(renderUnit)
            } else {
                renderGroups[key] = RenderGroup(renderUnit: renderUnit, mtkView: mtkView)
            }
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

        var index: Float = 0

        for (_, renderGroup) in renderGroups {
            renderEncoder.setRenderPipelineState(renderGroup.pipelineState)

            renderGroup.renderUnits.forEach { renderUnit in
                index += 1
                renderEncoder.setVertexBuffer(renderUnit.vertBuffer, offset: 0, index: 0)


                timer += 0.005
                var currentTime = sin(timer * index)
                renderEncoder.setFragmentBytes( &currentTime,
                length: MemoryLayout<Float>.stride, index: 5)

                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: 6,
                                                    indexType: .uint16,
                                                    indexBuffer: renderUnit.indexBuffer,
                                                    indexBufferOffset: 0)
            }
        }

        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
