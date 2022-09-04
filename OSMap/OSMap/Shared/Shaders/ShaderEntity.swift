//
//  ShaderLibrary.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import Foundation
import Metal

class ShaderEntity {
    init(vertName: String,
         fragName: String,
         for device: MTLDevice)
    {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: vertName)
        let fragmentFunction = library?.makeFunction(name: fragName)
    }
}
