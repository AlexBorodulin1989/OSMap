//
//  RenderUnit.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

class RenderUnit {

    let vertBuffer: MTLBuffer
    let indexBuffer: MTLBuffer

    let primitiveType: Entity.Type

    init(primitive: Entity, device: MTLDevice) {
        guard let vertexBuffer = device.makeBuffer(bytes: primitive.verts,
                                                   length: MemoryLayout<Float>.stride * primitive.verts.count)
        else {
            fatalError("Fatal error: cannot create vertex buffer for Frame")
        }

        self.vertBuffer = vertexBuffer

        guard let indexBuffer = device.makeBuffer(bytes: primitive.indices,
                                                  length: MemoryLayout<UInt16>.stride * primitive.indices.count)
        else {
            fatalError("Fatal error: cannot create index buffer for Frame")
        }
        self.indexBuffer = indexBuffer

        primitiveType = type(of: primitive)
    }
}

extension RenderUnit {
    func pipelineState(device: MTLDevice, pixelColorFormat: MTLPixelFormat) -> MTLRenderPipelineState {

        guard let library = device.makeDefaultLibrary(),
              let vertFunc = library.makeFunction(name: primitiveType.vertShader),
              let fragFunc = library.makeFunction(name: primitiveType.fragShader)
        else {
            fatalError("Fatal error: cannot make shader")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelColorFormat
        pipelineDescriptor.vertexDescriptor = primitiveType.vertexDescriptor

        let pipelineState: MTLRenderPipelineState!

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        return pipelineState
    }
}
