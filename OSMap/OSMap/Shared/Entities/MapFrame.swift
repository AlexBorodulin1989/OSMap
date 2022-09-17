//
//  MapFrame.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

import MetalKit

class MapFrame {
    
    var tiles = [[TileFrame]]()

    let pipelineState: MTLRenderPipelineState

    init(device: MTLDevice, imageName: String) {
        pipelineState = TileFrame.pipelineState(device: device, pixelColorFormat: .bgra8Unorm)
        let tile = TileFrame(device: device, imageName: imageName)
        tiles.append([tile])
    }
}

extension MapFrame: RenderItem {
    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(pipelineState)
        tiles.forEach { $0.first?.draw(engine: engine, encoder: encoder) }
    }
}
