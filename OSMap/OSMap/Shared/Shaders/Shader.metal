//
//  Shader.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

#include <metal_stdlib>
using namespace metal;


vertex float4 map_vertex(float4 pos [[attribute(0)]] [[stage_in]],
                         uint vertexID [[vertex_id]])
{
    return pos;
}

fragment float4 map_fragment() {
    return float4(0, 0, 1, 1);
}
