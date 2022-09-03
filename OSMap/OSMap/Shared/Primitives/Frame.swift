//
//  Frame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

struct Frame {
    var vertices: [Float] = [
        -1, 1, 0,
         1, 1, 0,
         -1, -1, 0,
         1, -1, 0
    ]

    var indices: [UInt16] = [
        0, 3, 2,
        0, 1, 3
    ]

    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer

    init(device: MTLDevice) {
        guard let vertexBuffer = device.makeBuffer(bytes: &vertices,
                                                   length: MemoryLayout<Float>.stride * vertices.count)
        else {
            fatalError("Creating vertex buffer failed")
        }

        self.vertexBuffer = vertexBuffer

        guard let indexBuffer = device.makeBuffer(bytes: &indices,
                                                  length: MemoryLayout<UInt16>.stride * indices.count)
        else {
            fatalError("Creating index buffer failed")
        }
        self.indexBuffer = indexBuffer
    }
}
