//
//  RenderUnit.swift
//  OSMap
//
//  Created by Aleksandr Borodulin on 04.09.2022.
//

import MetalKit

protocol RenderItem {

    static var vertexDescriptor: MTLVertexDescriptor { get }

    static var vertShader: String { get }
    static var fragShader: String { get }

    func vertexBuffer(for device: MTLDevice) -> MTLBuffer
    func indexBuffer(for device: MTLDevice) -> MTLBuffer

    func draw(engine: RenderEngine, encoder: MTLRenderCommandEncoder)
}

extension RenderItem {
    static func pipelineState(device: MTLDevice, pixelColorFormat: MTLPixelFormat) -> MTLRenderPipelineState {

        guard let library = device.makeDefaultLibrary(),
              let vertFunc = library.makeFunction(name: vertShader),
              let fragFunc = library.makeFunction(name: fragShader)
        else {
            fatalError("Fatal error: cannot make shader")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertFunc
        pipelineDescriptor.fragmentFunction = fragFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelColorFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        let pipelineState: MTLRenderPipelineState!

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        return pipelineState
    }
}

