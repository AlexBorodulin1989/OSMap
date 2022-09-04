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
        let library = mtkView.device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "map_vertex")
        let fragmentFunction = library?.makeFunction(name: "map_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = primitive.vertexDescriptor

        do {
            pipelineState = try mtkView.device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}
