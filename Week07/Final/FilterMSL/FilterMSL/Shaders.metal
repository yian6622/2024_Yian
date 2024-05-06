//
//  Shaders.metal
//  FilterMSL
//
//  Created by 陈逸安 on 4/29/24.
//

#include <metal_stdlib>
using namespace metal;

// Vertex Shader
vertex float4 basic_vertex(const device float4* vertexArray [[ buffer(0) ]],
                           uint vertexID [[ vertex_id ]]) {
    return vertexArray[vertexID];
}

// Fragment Shader
fragment float4 shader_day70(float4 pixPos [[position]],
                             constant float2& res [[buffer(0)]],
                             constant float& time [[buffer(1)]],
                             texture2d<float, access::sample> texture [[texture(2)]],
                             sampler textureSampler [[sampler(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = pixPos.xy / res.xy;

    float4 c = texture.sample(s, uv);
    c = sin(uv.x * 10.0 + c * cos(c * 6.28 + time + uv.x) * sin(c + uv.y + time) * 6.28) * 0.5 + 0.5;
    c.b += length(c.rg);
    return c;
}
