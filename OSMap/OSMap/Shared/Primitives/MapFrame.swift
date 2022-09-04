//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

struct MapFrame: Primitive {

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

    let vertShader: String = "map_vertex"
    let fragShader: String = "map_fragment"

    var vertexDescriptor: MTLVertexDescriptor {
        let vertDescriptor = MTLVertexDescriptor()
        vertDescriptor.attributes[0].format = .float3
        vertDescriptor.attributes[0].offset = 0
        vertDescriptor.attributes[0].bufferIndex = 0

        let stride = MemoryLayout<Float>.stride * 3
        vertDescriptor.layouts[0].stride = stride
        return vertDescriptor
    }

    static let group: String = "MapFrame"
}
