//
//  Primitive.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

protocol RenderEntity {
    // grouping by unique vertex, fragment shader, data format and memory layout
    static var group: String { get }

    static var vertexDescriptor: MTLVertexDescriptor { get }

    static var vertShader: String { get }
    static var fragShader: String { get }

    func vertexBuffer(for device: MTLDevice) -> MTLBuffer
    func indexBuffer(for device: MTLDevice) -> MTLBuffer
}
