//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

class MapFrame {

    var visibleTilesByDimCount = 2
    
    var tiles = [[TileFrame]]()

    let pipelineState: MTLRenderPipelineState

    init(device: MTLDevice, imageName: String) {
        pipelineState = TileFrame.pipelineState(device: device, pixelColorFormat: .bgra8Unorm)

        let dimSize: Float = 1 / Float(visibleTilesByDimCount)

        for row in 0..<visibleTilesByDimCount {
            var columnTiles = [TileFrame]()
            for column in 0..<visibleTilesByDimCount {
                let tile = TileFrame(device: device, imageName: imageName)

                let leftPointX = (Float(row) * dimSize) * 2 - 1
                let rightPointX = (Float(row) * dimSize + dimSize) * 2 - 1

                let leftTop = SIMD3<Float>(leftPointX, (Float(column) * dimSize + dimSize) * 2 - 1, 1)
                let rightTop = SIMD3<Float>(rightPointX, (Float(column) * dimSize + dimSize) * 2 - 1, 1)
                let rightBottom = SIMD3<Float>(rightPointX, (Float(column) * dimSize) * 2 - 1, 1)
                let leftBottom = SIMD3<Float>(leftPointX, (Float(column) * dimSize) * 2 - 1, 1)

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
    }
}

extension MapFrame: RenderItem {
    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(pipelineState)
        tiles.flatMap{$0}.forEach { $0.draw(engine: engine, encoder: encoder) }
    }
}
