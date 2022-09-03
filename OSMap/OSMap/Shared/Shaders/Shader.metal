#include <metal_stdlib>
using namespace metal;


vertex float4 map_vertex(constant packed_float3 *vertices [[buffer(0)]],
                         constant ushort *indices [[buffer(1)]],
                         uint vertexID [[vertex_id]])
{
    ushort index = indices[vertexID];
    float4 position = float4(vertices[index], 1);
    return position;
}

fragment float4 map_fragment() {
    return float4(0, 0, 1, 1);
}
