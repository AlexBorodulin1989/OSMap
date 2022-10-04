//
//  TileFrame.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 17.09.2022.
//

import MetalKit
import Cocoa
import Combine

extension TileFrame {
    struct Point {
        var pos: SIMD3<Float>
        var texUV: SIMD2<Float>
    }
}

class TileFrame: RenderItem {
    let visibleTilesCountByDimension = 2

    var verts: [Point] = []

    var indices: [UInt16] = [
        0, 1, 2,
        0, 2, 3
    ]

    var vertBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!

    var texture: Texture?

    static var vertShader: String { "map_vertex" }
    static var fragShader: String { "map_fragment" }

    let initialCameraDist: Float = 1

    var zoom: Int = MapFrame.Constants.initialZoom {
        didSet {
            if oldValue != zoom {
                self.texture = Texture(device: device, imageName: "no_img.png")
                loadImage()
            }
        }
    }

    var cameraOffset: Float = 0.0

    let row: Int
    let column: Int

    var x: Float = 0.0
    var y: Float = 0.0

    private var cancellables = Set<AnyCancellable>()

    let device: MTLDevice! //need to delete added only for quick solution

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

    required init(device: MTLDevice, params: Any...) {
        self.device = device

        if let params = params.first as? [Int] {
            self.texture = Texture(device: device, imageName: "no_img.png")
            column = params[1]
            row = params[2]

            self.loadImage()
        } else {
            row = 0
            column = 0
        }
    }

    func loadImage() {
        let visibleTilesCountPerDim = NSDecimalNumber(decimal: pow(2.0, zoom) + MapFrame.Constants.epsilon).intValue

        let firstTileIndexRow = Int(round((x + 1) * 0.5 * Float(visibleTilesCountPerDim)))
        let firstTileIndexColumn = Int(round((y + 1) * 0.5 * Float(visibleTilesCountPerDim)))

        let request = URLRequest(url: URL(string: "https://tile.openstreetmap.org/\(zoom)/\(firstTileIndexColumn + column)/\(firstTileIndexRow + row).png")!)
        let publisher: URLSession.RequestTilePublisher = URLSession.RequestTilePublisher(urlRequest: request)
        publisher
            .sink { error in

            } receiveValue: { data in
                DispatchQueue.main.async {[weak self] in
                    guard let self = self
                    else {
                        return
                    }
                    let image = NSImage(data: data)!
                    let data = self.jpegDataFrom(image:image)

                    if let image = NSImage(data: data) {
                        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                        if let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) {
                            do {
                                let mtlTexture = try MTKTextureLoader(device: self.device).newTexture(cgImage: imageRef, options: nil)
                                self.texture = Texture(mtlTexture: mtlTexture)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }

                    }
                }
            }.store(in: &cancellables)
    }

    func jpegDataFrom(image:NSImage) -> Data {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
        return jpegData
    }

    func setVertices(verts: [Point], device: MTLDevice) {
        self.verts = verts
        self.vertBuffer = vertexBuffer(for: device)
        self.indexBuffer = indexBuffer(for: device)
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
        let near: Float = 0.05

        let interval = far - near

        let a = far / interval
        let b = -far * near / interval

        let projMatrix: matrix_float4x4

        if engine.aspectRatio < 1 { // width > height
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

        var cameraDistance = initialCameraDist - cameraOffset

        let camDistInverted = NSDecimalNumber(decimal: pow(2.0, zoom - MapFrame.Constants.initialZoom)).floatValue

        cameraDistance = cameraDistance*camDistInverted

        let camOffset = initialCameraDist - cameraDistance

        let viewMatrix = matrix_float4x4([
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, -camOffset, 1)
        ])


        var cam = Camera(projection: projMatrix, view: viewMatrix)

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
