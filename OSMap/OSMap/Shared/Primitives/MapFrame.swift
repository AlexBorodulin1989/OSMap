//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

struct MapFrame {
    var verts: [Float] = [
        -1, 1, 0,
         1, 1, 0,
         -1, -1, 0,
         1, -1, 0
    ]

    var indices: [UInt16] = [
        0, 3, 2,
        0, 1, 3
    ]

    lazy var vertexDescriptor: MTLVertexDescriptor = {
        let vertDescriptor = MTLVertexDescriptor()
        vertDescriptor.attributes[0].format = .float3
        vertDescriptor.attributes[0].offset = 0
        vertDescriptor.attributes[0].bufferIndex = 0

        let stride = MemoryLayout<Float>.stride * 3
        vertDescriptor.layouts[0].stride = stride
        return vertDescriptor
    }()

    let vertBuffer: MTLBuffer
    let indexBuffer: MTLBuffer

    init(device: MTLDevice) {
        guard let vertexBuffer = device.makeBuffer(bytes: &verts,
                                                   length: MemoryLayout<Float>.stride * verts.count)
        else {
            fatalError("Creating vertex buffer failed")
        }

        self.vertBuffer = vertexBuffer

        guard let indexBuffer = device.makeBuffer(bytes: &indices,
                                                  length: MemoryLayout<UInt16>.stride * indices.count)
        else {
            fatalError("Creating index buffer failed")
        }
        self.indexBuffer = indexBuffer
    }
}
