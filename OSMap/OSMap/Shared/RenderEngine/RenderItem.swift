//
//  RenderUnit.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

class RenderItem {

    let vertBuffer: MTLBuffer
    let indexBuffer: MTLBuffer

    let primitiveType: RenderEntity.Type

    init(entity: RenderEntity, device: MTLDevice) {
        guard let vertexBuffer = device.makeBuffer(bytes: entity.verts,
                                                   length: MemoryLayout<Float>.stride * entity.verts.count)
        else {
            fatalError("Fatal error: cannot create vertex buffer for Frame")
        }

        self.vertBuffer = vertexBuffer

        guard let indexBuffer = device.makeBuffer(bytes: entity.indices,
                                                  length: MemoryLayout<UInt16>.stride * entity.indices.count)
        else {
            fatalError("Fatal error: cannot create index buffer for Frame")
        }
        self.indexBuffer = indexBuffer

        primitiveType = type(of: entity)
    }
}

extension RenderItem {
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
