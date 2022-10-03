//
//  RenderUnit.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

protocol RenderItem {
    init(device: MTLDevice, params: Any...)

    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder)
}
