//
//  MapShader.swift
//  Pipeline
//
//  Created by Aleksandr Borodulin on 03.09.2022.
//

#include <metal_stdlib>
using namespace metal;

struct Camera {
    float4x4 projection;
};

struct MapVertex {
    float4 pos [[attribute(0)]];
    float2 texUV [[ attribute(1) ]];
};

struct MapFragment {
    float4 pos [[position]];
    float2 texUV;
};

vertex MapFragment map_vertex(MapVertex vert [[stage_in]],
                              constant Camera &camera [[ buffer(1) ]])
{
    MapFragment frag;
    frag.pos = camera.projection * vert.pos;
    frag.texUV = vert.texUV;

    return frag;
}

fragment half4 map_fragment(MapFragment frag [[stage_in]],
                            texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler s = sampler(coord::normalized, address::clamp_to_zero, filter::linear);
    float4 color = texture.sample(s, frag.texUV);
    return half4(color.r, color.g, color.b, 1);
}
