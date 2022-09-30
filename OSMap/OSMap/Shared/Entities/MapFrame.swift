//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit
import Combine

class MapFrame: RenderItem {
    private var visibleTilesByDimCount = 2
    
    private var tiles = [[TileFrame]]()

    private let pipelineState: MTLRenderPipelineState

    var cancellables = Set<AnyCancellable>()

    private var cameraOffset: Float = 0

    var mouseWeelEvent: NSEvent? {
        didSet {
            let cameraDistance = 1 - cameraOffset
            cameraOffset += Float(mouseWeelEvent?.scrollingDeltaY ?? 0) * cameraDistance * 0.01
            if cameraOffset < 0 {
                cameraOffset = 0
            }
        }
    }

    required init(device: MTLDevice, params: Any...) {
        pipelineState = TileFrame.pipelineState(device: device, pixelColorFormat: .bgra8Unorm)

        let dimSize: Float = 2 / Float(visibleTilesByDimCount)

        for row in 0..<visibleTilesByDimCount {
            var columnTiles = [TileFrame]()
            for column in 0..<visibleTilesByDimCount {
                let tile = TileFrame(device: device, params: [1, row, column])

                let leftPointX = (Float(row) * dimSize) - 1
                let rightPointX = (Float(row) * dimSize + dimSize) - 1
                let topPointY = 1 - Float(column) * dimSize
                let bottomPointY = 1 - (Float(column) * dimSize) - dimSize

                let leftTop = SIMD3<Float>(leftPointX, topPointY, 1)
                let rightTop = SIMD3<Float>(rightPointX, topPointY, 1)
                let rightBottom = SIMD3<Float>(rightPointX, bottomPointY, 1)
                let leftBottom = SIMD3<Float>(leftPointX, bottomPointY, 1)

                let verts: [TileFrame.Point] = [
                    TileFrame.Point(pos: leftTop, texUV: SIMD2<Float>(0, 0)),
                    TileFrame.Point(pos: rightTop, texUV: SIMD2<Float>(1, 0)),
                    TileFrame.Point(pos: rightBottom, texUV: SIMD2<Float>(1, 1)),
                    TileFrame.Point(pos: leftBottom, texUV: SIMD2<Float>(0, 1))
                ]

                tile.setVertices(verts: verts, device: device)

                columnTiles.append(tile)
            }

            tiles.append(columnTiles)
        }

        setScrollWeelListener()
    }
}

extension MapFrame {
    func setScrollWeelListener() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
            .throttle(for: .milliseconds(1), scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.mouseWeelEvent, on: self)
            .store(in: &cancellables)
    }
}

extension MapFrame {
    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(pipelineState)
        tiles.flatMap{$0}.forEach {[weak self] tile in
            tile.cameraOffset = self?.cameraOffset ?? 0
            tile.draw(engine: engine, encoder: encoder)
        }
    }
}
