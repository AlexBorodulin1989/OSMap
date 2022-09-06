//
//  RenderUnit.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

class RenderUnit {

    var pipelineState: MTLRenderPipelineState!

    let vertBuffer: MTLBuffer
    let indexBuffer: MTLBuffer

    init(primitive: Primitive, mtkView: MTKView) {


        guard let vertexBuffer = mtkView.device?.makeBuffer(bytes: primitive.verts,
                                                            length: MemoryLayout<Float>.stride * primitive.verts.count)
        else {
            fatalError("Fatal error: cannot create vertex buffer for Frame")
        }

        self.vertBuffer = vertexBuffer

        guard let indexBuffer = mtkView.device?.makeBuffer(bytes: primitive.indices,
                                                           length: MemoryLayout<UInt16>.stride * primitive.indices.count)
        else {
            fatalError("Fatal error: cannot create index buffer for Frame")
        }
        self.indexBuffer = indexBuffer

        addPipelineDescriptor(primitive: primitive, mtkView: mtkView)
    }
}

extension RenderUnit {
    func addPipelineDescriptor(primitive: Primitive, mtkView: MTKView) {
        guard let device = mtkView.device
        else {
            fatalError("Fatal error: device not found")
        }

        let shaderInfo = ShaderManager.shared.getShaderInfo(for: type(of: primitive).vertShader,
                                                            fragName: type(of: primitive).fragShader,
                                                            for: device)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = shaderInfo.vertFunc
        pipelineDescriptor.fragmentFunction = shaderInfo.fragFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = primitive.vertexDescriptor

        do {
            pipelineState = try mtkView.device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}