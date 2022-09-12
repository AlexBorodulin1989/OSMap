//
//  MapShader.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

#include <metal_stdlib>
using namespace metal;

struct MapVertex {
    float4 pos [[attribute(0)]];
    float2 texUV [[ attribute(1) ]];
};

struct MapFragment {
    float4 pos [[position]];
    float2 texUV;
};

vertex float4 map_vertex(MapVertex vert [[stage_in]],
                         uint vertexID [[vertex_id]])
{
    MapFragment frag;
    frag.pos = vert.pos;
    frag.texUV = vert.texUV;

    return vert.pos;
}

fragment half4 map_fragment(MapFragment frag [[stage_in]]) {
    constexpr sampler s = sampler(coord::normalized, address::clamp_to_zero, filter::linear);
    return half4(0, 1, 1, 1);
}
