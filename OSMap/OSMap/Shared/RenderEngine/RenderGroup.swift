//
//  RenderGroup.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 05.09.2022.
//

import MetalKit

class RenderGroup {
    private(set) var renderUnits = [RenderItem]()
    let pipelineState: MTLRenderPipelineState

    init(renderItem: RenderItem, device: MTLDevice, pixelColorFormat: MTLPixelFormat) {
        renderUnits = [renderItem]
        pipelineState = renderItem.pipelineState(device: device,
                                                 pixelColorFormat: pixelColorFormat)
    }

    func addRenderUnit(_ renderItem: RenderItem) {
        renderUnits.append(renderItem)
    }
}
