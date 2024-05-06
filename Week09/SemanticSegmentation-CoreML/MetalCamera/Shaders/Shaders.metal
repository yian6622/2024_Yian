#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float2 text_coord;
};

struct TwoInputVertex
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
};

struct Uniforms {
    float4x4 scaleMatrix;
};

vertex Vertex vertex_render_target(constant Vertex *vertexes [[ buffer(0) ]],
                                   constant Uniforms &uniforms [[ buffer(1) ]],
                                   uint vid [[vertex_id]])
{
    Vertex out = vertexes[vid];
    out.position = uniforms.scaleMatrix * out.position;// * in.position;
    return out;
};

vertex TwoInputVertex two_vertex_render_target(const device packed_float2 *position [[buffer(0)]],
                                               const device packed_float2 *texturecoord [[buffer(1)]],
                                               const device packed_float2 *texturecoord2 [[buffer(2)]],
                                               uint vid [[vertex_id]]) {
    TwoInputVertex outputVertices;
    outputVertices.position = float4(position[vid], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    outputVertices.textureCoordinate2 = texturecoord2[vid];
    return outputVertices;
};


fragment float4 fragment_render_target(Vertex vertex_data [[ stage_in ]],
                                       texture2d<float> tex2d [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, vertex_data.text_coord));
    return color;
};

fragment float4 gray_fragment_render_target(Vertex vertex_data [[ stage_in ]],
                                            texture2d<float> tex2d [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, vertex_data.text_coord));
    float gray = (color[0] + color[1] + color[2])/3;
    return float4(gray, gray, gray, 1.0);
};

typedef struct
{
    float mixturePercent;
} AlphaBlendUniform;

fragment half4 alphaBlendFragment(TwoInputVertex fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  texture2d<half> inputTexture2 [[texture(1)]],
                                  constant AlphaBlendUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    constexpr sampler quadSampler2;
    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);

    return half4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * half(uniform.mixturePercent)), textureColor.a);
}

fragment half4 maskFragment(TwoInputVertex fragmentInput [[stage_in]],
                            texture2d<half> inputTexture [[texture(0)]],
                            texture2d<half> inputTexture2 [[texture(1)]])
{
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    constexpr sampler quadSampler2;
    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);

    if(textureColor2.r + textureColor2.g + textureColor2.b > 0) {
        return textureColor;
    } else {
        return half4(0, 0, 0 ,0);
    }
}

typedef struct
{
    int32_t classNum;
} SegmentationValue;

typedef struct
{
    int32_t targetClass;
    int32_t width;
    int32_t height;
} SegmentationUniform;

fragment float4 segmentation_render_target(Vertex vertex_data [[ stage_in ]],
                                           constant SegmentationValue *segmentation [[ buffer(0) ]],
                                           constant SegmentationUniform& uniform [[ buffer(1) ]])
{
    int index = int(vertex_data.position.x) + int(vertex_data.position.y) * uniform.width;
    if(segmentation[index].classNum == uniform.targetClass) {
        return float4(1.0, 0, 0, 1.0); // red // (r, g, b, a)
    }

    return float4(0,0,0,1.0); // black
};

typedef struct
{
    int32_t numberOfClasses;
    int32_t width;
    int32_t height;
} MultitargetSegmentationUniform;

fragment float4 multitarget_segmentation_render_target(Vertex vertex_data [[ stage_in ]],
                                           constant SegmentationValue *segmentation [[ buffer(0) ]],
                                           constant MultitargetSegmentationUniform& uniform [[ buffer(1) ]])
{
    int index = int(vertex_data.position.x) + int(vertex_data.position.y) * uniform.width;
    
    if (segmentation[index].classNum == 0) { // background case
        return float4(0,0,0,1.0); // black
    }
    
    float h_ratio = float(segmentation[index].classNum) / float(uniform.numberOfClasses);
    h_ratio = (1.0 - h_ratio) + 0.12/*extra value*/;
    h_ratio = h_ratio > 1.0 ? h_ratio - 1.0 : h_ratio;
    float h = 360 * h_ratio;
    
    float angle = h; //(h >= 360.0 ? 0.0 : h);
    float sector = angle / 60.0; // Sector
    float i = floor(sector);
    int i_int = int(sector);
    float f = sector - i; // Factorial part of h
    
    float p = 0.0;
    float q = 1.0 - f;
    float t = f;
    
    if (i_int == 0) {
        return float4(1.0, t, p, 1.0);
    } else if (i_int == 1) {
        return float4(q, 1.0, p, 1.0);
    } else if (i_int == 2) {
        return float4(p, 1.0, t, 1.0);
    } else if (i_int == 3) {
        return float4(p, q, 1.0, 1.0);
    } else if (i_int == 4) {
        return float4(t, p, 1.0, 1.0);
    } else {
        return float4(1.0, p, q, 1.0);
    }
    
    return float4(0,0,0,1.0); // black
};

fragment half4 lookupFragment(TwoInputVertex fragmentInput [[stage_in]],
                              texture2d<half> inputTexture [[texture(0)]],
                              texture2d<half> inputTexture2 [[texture(1)]],
                              constant float& intensity [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 base = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    half blueColor = base.b * 63.0h;

    half2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0h);
    quad1.x = floor(blueColor) - (quad1.y * 8.0h);

    half2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0h);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0h);

    float2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.g);

    float2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * base.g);

    constexpr sampler quadSampler3;
    half4 newColor1 = inputTexture2.sample(quadSampler3, texPos1);
    constexpr sampler quadSampler4;
    half4 newColor2 = inputTexture2.sample(quadSampler4, texPos2);

    half4 newColor = mix(newColor1, newColor2, fract(blueColor));

    return half4(mix(base, half4(newColor.rgb, base.w), half(intensity)));
}

// MARK: - Day70

// https://www.shadertoy.com/view/MtBGDR 紫メタリック

fragment float4 shader_day70(float4 pixPos [[position]],
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

// MARK: - Ex002

// https://www.shadertoy.com/view/XlS3zt postalize

fragment float4 shader_Ex002(float4 pixPos [[position]],
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

// MARK: - Day41

// https://www.shadertoy.com/view/XldBzj

fragment float4 shader_day41(float4 pixPos [[position]],
                             constant float2& res [[buffer(0)]],
                             texture2d<float, access::sample> texture [[texture(1)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = pixPos.xy / res.xy;

    float2 scaled_uv = uv * 75.0;
    float2 begin = floor(scaled_uv) / 75.0;
    float grey = pow(length(texture.sample(s, begin).rgb) / sqrt(3.0), 0.66);
    grey = 1.0 - grey;
    grey = 75.0 * distance(uv, begin + float2(0.5 / 75.0, 0.5 / 75.0)) > grey ? 1.0 : 0.0;
    return float4(float3(250.0, 242.0, 228.0) / 256.0 * grey, 1.0);
}
