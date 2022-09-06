//
//  RenderGroup.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 05.09.2022.
//

import Foundation

class RenderGroup {
    private var renderUnits = [RenderUnit]()

    func addRenderUnit(_ renderUnit: RenderUnit) {
        renderUnits.append(renderUnit)
    }
}
