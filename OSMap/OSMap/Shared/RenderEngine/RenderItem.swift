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
        

        self.vertBuffer = entity.vertexBuffer(for: device)
        self.indexBuffer = entity.indexBuffer(for: device)

        primitiveType = type(of: entity) // rename to entityType
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
