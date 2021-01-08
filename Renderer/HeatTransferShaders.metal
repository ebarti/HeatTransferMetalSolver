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
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];
    float4  color;
} Vertex;

static float4 getColor(const float temperature, const EBShaderParams params) {
    // Color Map
    //              R   G   B
    // Initial     255  0   0
    // Fluid        0  255  0
    float4 color;
    float deltaT = params.initialTemperature-params.fluidTemperature;
    float red = temperature/deltaT - params.fluidTemperature/deltaT;
    //
    //float green = temperature/(params.fluidTemperature-params.initialTemperature) - params.initialTemperature/(params.fluidTemperature-params.initialTemperature);
    //float red = temperature/(params.initialTemperature - params.fluidTemperature) - params.fluidTemperature/(params.initialTemperature)
       
    color.r = 0xFF*red;
    color.g = 0xFF*(1-red);
    color.b = 0x00;
    color.w = 0xFF;
    return color;
}

vertex Vertex vertexShader(uint                         vertexID    [[ vertex_id                                ]],
                           const device float*          temperature [[ buffer(EBRenderBufferIndexTemperatures)  ]],
                           constant EBShaderParams &    params      [[ buffer(EBRenderBufferIndexParams)        ]],
                           constant EBUniforms &        uniforms    [[ buffer(EBRenderBufferIndexUniforms)      ]])
{
    uint32_t posn = vertexID;
    float x,y,z,w;
    x = y = z = w = 0.f;
    x = posn % params.numXElements;
    // (idx - x) / SIZE_X = +  * (y + SIZE_Y * z)
    posn -= (uint32_t)x;
    posn /= params.numXElements;
    // (idx - x) / SIZE_X = posn = y + SIZE_Y * z
    y = posn % params.numYElements;
    posn -= (uint32_t)y;
    posn /= params.numYElements;
    // (posn  - y)/SIZE_Y = z
    z = posn;
    
    w = params.numXElements * params.numYElements * params.numZElements;
    
    float4 calcPosition;
    calcPosition.x = x;
    calcPosition.y = y;
    calcPosition.z = z;
    calcPosition.w = w;
    
    // Transform the coordinataes of the temperature array by index
    float deltaT = params.initialTemperature-params.fluidTemperature;
    float red = temperature[vertexID]/deltaT - params.fluidTemperature/deltaT;
    
    Vertex out;
    
    // Calculate the position of the vertex in clip space and output for clipping and rasterization
    out.position = uniforms.mvpMatrix * calcPosition;

    // Pass along the texture coordinate of the vertex for the fragment shader to use to sample from
    // the texture
     // Convert value to color here
    out.color.r = 0xFF*red;
    out.color.g = 0xFF*(1-red);
    out.color.b = 0x00;
    out.color.w = 0xFF;
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

