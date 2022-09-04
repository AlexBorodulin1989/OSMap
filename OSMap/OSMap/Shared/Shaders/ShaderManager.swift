//
//  ShaderLibrary.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import Foundation
import Metal

struct ShaderInfo {
    let vertFunc: MTLFunction
    let fragFunc: MTLFunction
}

class ShaderManager {
    static let shared = ShaderManager()

    private var uniqueShaderLibrary = [String: ShaderInfo]()

    private init() {}

    func getShaderInfo(for vertName: String,
                       fragName: String,
                       for device: MTLDevice) -> ShaderInfo
    {

        let uniqueKey = "\(vertName)\(fragName)"

        if let library = uniqueShaderLibrary[uniqueKey] {
            return library
        } else {
            guard let library = device.makeDefaultLibrary(),
                  let vertFunction = library.makeFunction(name: vertName),
                  let fragFunction = library.makeFunction(name: fragName)
            else {
                fatalError("Fatal error: cannot make shader")
            }

            let shaderInfo = ShaderInfo(vertFunc: vertFunction,
                                        fragFunc: fragFunction)

            uniqueShaderLibrary[uniqueKey] = shaderInfo

            return ShaderInfo(vertFunc: vertFunction, fragFunc: fragFunction)
        }
    }
}
