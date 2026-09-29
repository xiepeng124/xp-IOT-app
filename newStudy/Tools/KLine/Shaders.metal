
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

// 顶点着色器：简单传递位置和颜色
vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant VertexIn *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID].position, 0.0, 1.0);
    out.color = vertices[vertexID].color;
    return out;
}

// 片段着色器：输出插值后的颜色
fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}

