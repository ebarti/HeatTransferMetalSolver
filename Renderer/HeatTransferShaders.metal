//
//  HeatTransferShaders.metal
//  HeatTransfer
//
//  Created by Eloi on 12/30/20.
//
#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

#import "HeatTransferShaderTypes.h"

// Vertex shader outputs and per-fragment inputs
typedef struct
{
    float4 position [[position]];
    float4  color;
} Vertex;

vertex Vertex vertexShader(uint                    vertexID  [[ vertex_id ]],
                               const device float4*    position  [[ buffer(EBRenderBufferIndexPositions) ]],
                               const device uchar4*    color     [[ buffer(EBRenderBufferIndexColors)    ]],
                               constant EBUniforms & uniforms  [[ buffer(EBRenderBufferIndexUniforms)  ]])
{
    Vertex out;

    // Calculate the position of the vertex in clip space and output for clipping and rasterization
    out.position = uniforms.mvpMatrix * position[vertexID];

    // Pass along the texture coordinate of the vertex for the fragment shader to use to sample from
    // the texture
    out.color = float4(color[vertexID]); // Convert value to color here

    return out;
}

fragment float4 fragmentShader(Vertex       inColor  [[ stage_in    ]],
                              texture2d<half>  colorMap [[ texture(EBTextureIndexColorMap)  ]],
                              float2           texcoord [[ point_coord ]])
{
    constexpr sampler linearSampler (mip_filter::none,
                                     mag_filter::linear,
                                     min_filter::linear);

    half4 c = colorMap.sample(linearSampler, texcoord);

    float4 fragColor = (0.6h + 0.4h * inColor.color) * c.x;

    float4 x = float4(0.1h, 0.0h, 0.0h, fragColor.w);
    float4 y = float4(1.0h, 0.7h, 0.3h, fragColor.w);
    float  a = fragColor.w;

    return fragColor * mix(x, y, a);
}

