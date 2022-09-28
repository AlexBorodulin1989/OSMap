//
//  Texture.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 12.09.2022.
//

import MetalKit

class Texture {
    var mtlTexture: MTLTexture

    init(device: MTLDevice, imageName: String) {
        let textureLoader = MTKTextureLoader(device: device)

        var tex: MTLTexture!

        if let textureURL = Bundle.main.url(forResource: imageName, withExtension: nil) {
            do {
                tex = try textureLoader.newTexture(URL: textureURL)
            } catch {
                fatalError("Fatal error: texture cannot load")
            }
        }

        self.mtlTexture = tex
    }

    init(mtlTexture: MTLTexture) {
        self.mtlTexture = mtlTexture
    }
}
