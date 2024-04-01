#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position;
    float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]],
                              unsigned int vertexID [[vertex_id]],
                              constant float4x4 &projectionMatrix [[buffer(1)]]) {
    VertexOut out;
    Vertex in = vertexArray[vertexID];
    out.position = projectionMatrix * in.position;
    out.color = in.color;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
