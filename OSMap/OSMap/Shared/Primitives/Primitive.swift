//
//  Primitive.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

protocol Primitive {
    // grouping by unique vertex, fragment shader, data format and memory layout
    static var group: String { get }

    var vertexDescriptor: MTLVertexDescriptor { get }

    var verts: [Float] { get }
    var indices: [UInt16] { get }

    static var vertShader: String { get }
    static var fragShader: String { get }
}
