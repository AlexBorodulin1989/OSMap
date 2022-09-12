//
//  RenderGroup.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 05.09.2022.
//

import MetalKit

class RenderGroup {
    private(set) var renderUnits = [RenderUnit]()
    let pipelineState: MTLRenderPipelineState

    init(renderUnit: RenderUnit, device: MTLDevice, pixelColorFormat: MTLPixelFormat) {
        renderUnits = [renderUnit]
        pipelineState = renderUnit.pipelineState(device: device,
                                                 pixelColorFormat: pixelColorFormat)
    }

    func addRenderUnit(_ renderUnit: RenderUnit) {
        renderUnits.append(renderUnit)
    }
}
