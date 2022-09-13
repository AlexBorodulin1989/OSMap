//
//  RenderEngine.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

class RenderEngine: NSObject {
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue!

    private var library: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!

    let pixelColorFormat: MTLPixelFormat

    private var renderGroups = [String: RenderGroup]()

    init(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        self.device = device

        pixelColorFormat = mtkView.colorPixelFormat

        super.init()

        guard
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Fatal error: cannot create Queue")
        }
        self.commandQueue = commandQueue

        mtkView.device = device

        mtkView.clearColor = MTLClearColor(red: 1.0,
                                             green: 1.0,
                                             blue: 1.0,
                                             alpha: 1.0)

        mtkView.delegate = self
    }
}

extension RenderEngine {
    func addPrimitive(_ item: RenderItem) {
        let key = String(describing: type(of: item.self))
        
        if let renderGroup = renderGroups[key] {
            renderGroup.addRenderUnit(item)
        } else {
            renderGroups[key] = RenderGroup(renderItem: item,
                                            device: device,
                                            pixelColorFormat: pixelColorFormat)
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
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        for (_, renderGroup) in renderGroups {
            encoder.setRenderPipelineState(renderGroup.pipelineState)

            renderGroup.renderUnits.forEach { renderItem in
                renderItem.draw(encoder: encoder)
            }
        }

        encoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
