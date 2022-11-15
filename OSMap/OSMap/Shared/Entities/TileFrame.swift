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

    var x: Float = 0.0 {
        didSet {
            deltaX = (x - center.x) / (initialCameraDist - cameraOffset)
            if deltaX <= -tileSize || deltaX >= tileSize {
                loadImage()
            }
        }
    }

    var y: Float = 0.0
    {
        didSet {
            deltaY = (y - center.y) / (initialCameraDist - cameraOffset)
            if deltaY <= -tileSize || deltaY >= tileSize {
                loadImage()
            }
        }
    }

    var deltaX: Float = 0.0
    var deltaY: Float = 0.0

    var center = Position(x: 0, y: 0)

    let ndcSize: Float = 2

    private var cancellables = Set<AnyCancellable>()

    let device: MTLDevice! //need to delete added only for quick solution

    private let tileSize: Float

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

        self.texture = Texture(device: device, imageName: "no_img.png")

        guard let tileSize = params[0] as? Float,
              let column = params[1] as? Int,
              let row = params[2] as? Int
        else {
            fatalError()
        }

        self.tileSize = tileSize
        self.column = column
        self.row = row

        self.loadImage()
    }

    func loadImage() {
        let tilesPerDimension = NSDecimalNumber(decimal: pow(2.0, zoom) + MapFrame.Constants.epsilon).intValue + 2

        let firstTileIndexRow = Int(round((y + 1) * 0.5 * Float(tilesPerDimension)))
        let firstTileIndexColumn = Int(round((x + 1) * 0.5 * Float(tilesPerDimension)))

        if firstTileIndexRow <= 0 ||
            firstTileIndexColumn <= 0 ||
            firstTileIndexRow >= tilesPerDimension ||
            firstTileIndexColumn >= tilesPerDimension {
            return
        }

        let tileSize = ndcSize / Float(tilesPerDimension)

        center = Position(x: Float(firstTileIndexColumn) * tileSize - 1, y: Float(firstTileIndexRow) * tileSize - 1)

        let request = URLRequest(url: URL(string: "https://tile.openstreetmap.org/\(zoom)/\(firstTileIndexColumn + column - 1)/\(firstTileIndexRow + row - 1).png")!)
        let publisher: URLSession.RequestTilePublisher = URLSession.RequestTilePublisher(urlRequest: request)
        publisher
            .sink { error in

            } receiveValue: { data in
                DispatchQueue.main.async {[weak self] in
                    guard let self = self
                    else {
                        return
                    }
                    guard let image = NSImage(data: data)
                    else {
                        print("Dont load image")
                        return
                    }
                    var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                    if let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) {
                        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)

                        let cgContext = CGContext(data: nil,
                                                  width: imageRef.width,
                                                  height: imageRef.height,
                                                  bitsPerComponent: 8,
                                                  bytesPerRow: 0,
                                                  space: colorSpace!,
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

                        cgContext?.draw(imageRef, in: CGRect(origin: .zero, size: CGSize(width: imageRef.width, height: imageRef.height)))

                        guard let newCGImage = cgContext?.makeImage()
                        else {
                            print("Cannot load image")
                            return
                        }

                        let usage: MTLTextureUsage = .shaderRead

                        let textureOptions: [MTKTextureLoader.Option: Any] = [
                            .textureUsage: NSNumber(value: usage.rawValue),
                            .generateMipmaps: NSNumber(value: false),
                            .SRGB: NSNumber(value: false)
                        ]

                        do {
                            let mtlTexture = try MTKTextureLoader(device: self.device).newTexture(cgImage: newCGImage, options: textureOptions)
                            self.texture = Texture(mtlTexture: mtlTexture)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }.store(in: &cancellables)
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
            SIMD4<Float>(-deltaX, deltaY, -camOffset, 1)
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
