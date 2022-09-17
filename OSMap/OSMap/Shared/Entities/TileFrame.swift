//
//  TileFrame.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 17.09.2022.
//

import MetalKit

extension TileFrame {
    struct Point {
        var pos: SIMD3<Float>
        var texUV: SIMD2<Float>
    }
}

class TileFrame: RenderItem {
    let visibleTilesCountByDimension = 2

    var verts: [Point] = [
        Point(pos: SIMD3<Float>(-1, 1, 1), texUV: SIMD2<Float>(0, 0)),
        Point(pos: SIMD3<Float>(1, 1, 1), texUV: SIMD2<Float>(1, 0)),
        Point(pos: SIMD3<Float>(1, -1, 1), texUV: SIMD2<Float>(1, 1)),
        Point(pos: SIMD3<Float>(-1, -1, 1), texUV: SIMD2<Float>(0, 1))

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

    static func pipelineState(device: MTLDevice, pixelColorFormat: MTLPixelFormat) -> MTLRenderPipelineState {

        guard let library = device.makeDefaultLibrary(),
              let vertFunc = library.makeFunction(name: vertShader),
              let fragFunc = library.makeFunction(name: fragShader)
        else {
            fatalError("Fatal error: cannot make shader")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelColorFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        let pipelineState: MTLRenderPipelineState!

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        return pipelineState
    }

    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(texture?.mtlTexture, index: 0)

        let far: Float = 2
        let near: Float = 0.1

        let interval = far - near

        let a = far / interval
        let b = -far * near / interval

        let projMatrix: matrix_float4x4

        if engine.aspectRatio < 1 {
            projMatrix = matrix_float4x4([
                SIMD4<Float>(1, 0, 0, 0),
                SIMD4<Float>(0, 1/engine.aspectRatio, 0, 0),
                SIMD4<Float>(                 0, 0, a, 1),
                SIMD4<Float>(                 0, 0, b, 0)
            ])
        } else {
            projMatrix = matrix_float4x4([
                SIMD4<Float>(engine.aspectRatio, 0, 0, 0),
                SIMD4<Float>(                 0, 1, 0, 0),
                SIMD4<Float>(                 0, 0, a, 1),
                SIMD4<Float>(                 0, 0, b, 0)
            ])
        }


        var cam = Camera(projection: projMatrix)

        encoder.setVertexBytes(&cam,
                               length: MemoryLayout<Camera>.stride,
                               index: 1)

        encoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
        encoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: 6,
                                            indexType: .uint16,
                                            indexBuffer: indexBuffer,
                                            indexBufferOffset: 0)
    }
}
