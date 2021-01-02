//
//  HeatTransferShaderTypes.h
//  HeatTransfer
//
//  Created by Eloi on 12/30/20.
//

// Defines the primitives for rendering our heat trasnfer simulation of a 3D prism

#ifndef HeatTransferShaderTypes_h
#define HeatTransferShaderTypes_h
#include <simd/simd.h>
// Positions
typedef enum EBRenderBufferIndex
{
    EBRenderBufferIndexPositions = 0,
    EBRenderBufferIndexColors   = 1,
    EBRenderBufferIndexUniforms = 2,
} EBRenderBufferIndex;

// Texture - color = temperature
typedef enum EBTextureIndex
{
    EBTextureIndexColorMap = 0,
} EBTextureIndex;

// Uniforms
typedef struct
{
    matrix_float4x4 mvpMatrix; // modelViewProjectionMatrix

} EBUniforms;

#endif /* HeatTransferShaderTypes_h */
