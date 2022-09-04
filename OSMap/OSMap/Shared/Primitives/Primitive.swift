//
//  Primitive.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

protocol Primitive {
    static var group: String { get }

    var vertexDescriptor: MTLVertexDescriptor { get }

    var verts: [Float] { get }
    var indices: [UInt16] { get }

    var vertShader: String { get }
    var fragShader: String { get }
}
