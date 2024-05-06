//
//  Shaders.metal
//  SingleTest
//

#include <metal_stdlib>
#include "Common.h"


using namespace metal;

// MARK: - 01

// https://www.shadertoy.com/view/tttXD8

float rand(float2 p, float time) {
    float t = floor(time * 50.0) / 10.0;
    return fract(sin(dot(p, float2(t * 12.9898, t * 78.233))) * 43758.5453);
}

float noise(float2 uv, float blockiness, float time) {
    float2 lv = fract(uv);
    float2 id = floor(uv);
    float n1 = rand(id, time);
    float n2 = rand(id + float2(1.0, 0.0), time);
    float n3 = rand(id + float2(0.0, 1.0), time);
    float n4 = rand(id + float2(1.0, 1.0), time);
    float2 u = smoothstep(0.0, 1.0 + blockiness, lv);
    return mix(mix(n1, n2, u.x), mix(n3, n4, u.x), u.y);
}

float fbm(float2 uv, int count, float blockiness, float complexity, float time) {
    float val = 0.0;
    float amp = 0.5;
    while(count != 0) {
        val += amp * noise(uv, blockiness, time);
        amp *= 0.5;
        uv *= complexity;
        count--;
    }
    return val;
}

fragment float4 shader_01(float4 pixPos [[position]],
                             constant float2& res [[buffer(0)]],
                             constant float& time[[buffer(1)]],
                             texture2d<float, access::sample> texture [[texture(1)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = pixPos.xy / res.xy;
    float2 a = float2(uv.x * (res.x / res.y), uv.y);
    float2 uv2 = float2(a.x / res.x, exp(a.y));
    float2 id = floor(uv * 20.0);

    float shift = 0.9 * pow(fbm(uv2, int(rand(id) * 6.0), 10000.0, 400.0, time), 10.0);

    float scanline = abs(cos(uv.y * 400.0));
    scanline = smoothstep(0.0, 2.0, scanline);
    shift = smoothstep(0.00001, 0.2, shift);

    float colR = texture.sample(s, float2(uv.x + shift, uv.y)).r * (1. - shift);
    float colG = texture.sample(s, float2(uv.x - shift, uv.y)).g * (1. - shift) + rand(id) * shift;
    float colB = texture.sample(s, float2(uv.x - shift, uv.y)).b * (1. - shift);

    float3 f = float3(colR, colG, colB) - (0.1 * scanline);

    return float4(f, 1.0);
}

// MARK: - 02

// https://www.shadertoy.com/view/XlS3zt postalize

fragment float4 shader_02(float4 pixPos [[position]],
                             constant float2& res [[buffer(0)]],
                             constant float& time[[buffer(1)]],
                             texture2d<float, access::sample> texture [[texture(1)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = pixPos.xy / res.xy;
    uv = float2(floor(uv.x * 320.0) / 320.0, floor(uv.y * 240.0) / 240.0);
    float4 samplrr = texture.sample(s, uv);
    float4 samplrr2 = texture.sample(s, uv + float2(1./ 320.0,0.0));
    float4 samplrr3 = texture.sample(s, uv + float2(0.0,1./ 240.0));
    float4 samplrr4 = texture.sample(s, uv + float2(-1./ 320.0,0.0));
    float4 samplrr5 = texture.sample(s, uv + float2(0.0,-1./ 240.0));

    float I = floor(length(samplrr.rgb) + 0.5) * 0.5 + 1.2;
    float3 C = float3(
                floor(samplrr.r * 3.0) / 3.0 * I,
                floor(samplrr.g * 3.0) / 3.0 * I,
                floor(samplrr.b * 3.0) / 3.0 * I
                );
    float border = floor(distance(samplrr2, samplrr) + distance(samplrr3, samplrr) + distance(samplrr4, samplrr) + distance(samplrr5, samplrr) + 0.73);
    uv.x *= 0.6 + sin(uv.y / 7.0 + time) / 3.0;
    uv.y *= 0.3 + sin(uv.x + time) / 5.0;
    float3 finalColor = C * (1.0 - float3(border));

    return float4(finalColor, 1.0);
}

// MARK: - 03

// https://www.shadertoy.com/view/MtBGDR

fragment float4 shader_03(float4 pixPos [[position]],
                             constant float2& res [[buffer(0)]],
                             constant float& time[[buffer(1)]],
                             texture2d<float, access::sample> texture [[texture(1)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = pixPos.xy / res.xy;

    float4 c = texture.sample(s, uv);
    c = sin(uv.x * 10.0 + c * cos(c * 6.28 + time + uv.x) * sin(c + uv.y + time) * 6.28) * 0.5 +0.5;
    c.b += length(c.rg);
    return c;
}
