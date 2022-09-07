//
//  RenderGroup.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 05.09.2022.
//

import MetalKit

class RenderGroup {
    private var renderUnits = [RenderUnit]()
    private let pipelineState: MTLRenderPipelineState

    init(renderUnit: RenderUnit, mtkView: MTKView) {
        renderUnits = [renderUnit]
        pipelineState = renderUnit.pipelineState(mtkView: mtkView)
    }

    func addRenderUnit(_ renderUnit: RenderUnit) {
        renderUnits.append(renderUnit)
    }
}
