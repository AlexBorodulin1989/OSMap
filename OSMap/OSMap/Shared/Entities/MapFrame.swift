//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

extension MapFrame {
    struct Point {
        var pos: SIMD3<Float>
        var texUV: SIMD2<Float>
    }
}

class MapFrame: RenderItem {
    var verts: [Point] = [
        Point(pos: SIMD3<Float>(-1, 1, 0), texUV: SIMD2<Float>(0, 0)),
        Point(pos: SIMD3<Float>(1, 1, 0), texUV: SIMD2<Float>(1, 0)),
        Point(pos: SIMD3<Float>(1, -1, 0), texUV: SIMD2<Float>(1, 1)),
        Point(pos: SIMD3<Float>(-1, -1, 0), texUV: SIMD2<Float>(0, 1))

    ]

    var indices: [UInt16] = [
        0, 1, 2,
        0, 2, 3
    ]

    var vertBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!

    var texture: Texture?

    static var vertShader: String { "map_vertex" }
    static var fragShader: String { "map_fragment" }

    static var vertexDescriptor: MTLVertexDescriptor {
        let vertDescriptor = MTLVertexDescriptor()
        vertDescriptor.attributes[0].format = .float3
        vertDescriptor.attributes[0].offset = 0
        vertDescriptor.attributes[0].bufferIndex = 0

        vertDescriptor.attributes[1].format = .float2
        vertDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertDescriptor.attributes[1].bufferIndex = 0

        let stride = MemoryLayout<Point>.stride
        vertDescriptor.layouts[0].stride = stride
        return vertDescriptor
    }

    init(device: MTLDevice, imageName: String) {
        self.vertBuffer = vertexBuffer(for: device)
        self.indexBuffer = indexBuffer(for: device)

        self.texture = Texture(device: device, imageName: imageName)
    }

    func vertexBuffer(for device: MTLDevice) -> MTLBuffer {
        guard let vertexBuffer = device.makeBuffer(bytes: verts,
                                                   length: MemoryLayout<Point>.stride * verts.count)
        else {
            fatalError("Fatal error: cannot create vertex buffer for Frame")
        }

        return vertexBuffer
    }

    func indexBuffer(for device: MTLDevice) -> MTLBuffer {
        guard let indexBuffer = device.makeBuffer(bytes: indices,
                                                  length: MemoryLayout<UInt16>.stride * indices.count)
        else {
            fatalError("Fatal error: cannot create index buffer for Frame")
        }

        return indexBuffer
    }

    func draw(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(texture?.mtlTexture, index: 0)

        encoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
        encoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: 6,
                                            indexType: .uint16,
                                            indexBuffer: indexBuffer,
                                            indexBufferOffset: 0)
    }
}
