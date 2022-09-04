//
//  Primitive.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

protocol Primitive {
    var vertBuffer: MTLBuffer { get }
    var indexBuffer: MTLBuffer { get }
}
