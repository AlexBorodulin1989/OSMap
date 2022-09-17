//
//  RenderGroup.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 05.09.2022.
//

import MetalKit

class RenderGroup {
    private(set) var renderUnits = [RenderItem]()

    init(renderItem: RenderItem, device: MTLDevice, pixelColorFormat: MTLPixelFormat) {
        renderUnits = [renderItem]
    }

    func addRenderUnit(_ renderItem: RenderItem) {
        renderUnits.append(renderItem)
    }
}
