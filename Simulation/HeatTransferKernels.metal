//
//  HeatTransferKernels.metal
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#import "HeatTransferKernelTypes.h"

typedef enum HeatTransferDirection {
    north = 0,
    south = 1,
    east = 2,
    west = 3,
    top = 4,
    bottom = 5
} HeatTransferDirection;

static float cp(const float temp) {
    return 467.6;
}

static float lambda(const float temp) {
    float l = 29.0;
    if (temp < 1273.0) {
        l += (1273.0-temp)/900.0 + 29;
    }
    return l;
}

// Flat[x + SIZE_X * (y + SIZE_Y * z)] = Original[x, y, z]
static float A(const float t, const float tside[6], HeatTransferDirection direction, const EBPhysicalParams params){
    float a = 0.0;
    if (north == direction) {
        a += (lambda(t) + lambda(tside[north])) * params.xArea / (2.f * params.dX);
    } else if (south == direction) {
        a += (lambda(t) + lambda(tside[south])) * params.xArea / (2.f * params.dX);
    } else if (east == direction) {
        a += (lambda(t) + lambda(tside[east])) * params.yArea / (2.f * params.dY);
    } else if (west == direction) {
        a += (lambda(t) + lambda(tside[west])) * params.yArea / (2.f * params.dY);
    } else if (top == direction) {
        a += (lambda(t) + lambda(tside[top])) * params.zArea / (2.f * params.dZ);
    } else {
        a += (lambda(t) + lambda(tside[bottom])) * params.zArea / (2.f * params.dZ);
    }
    return a;
}

static float alpha(const float temp) {
    return -5561.455 + 53.22458*temp - 0.1940006*pow(temp,2.0) + 0.0003336*pow(temp,3.0) - 2.548565e-7*pow(temp,4.0) + 6.988594e-11*pow(temp,5.0);
}

static float ComputeAux(const float T, const float north_t, const float south_t, const float east_t, const float west_t, const float top_t, const float bottom_t, const EBPhysicalParams params) {
    return 0.0;
}


kernel void ComputeQn(device float4*              tn                 [[ buffer(EBComputeQnBufferIndexTn)     ]],
                      device float4*              qn                 [[ buffer(EBComputeQnBufferIndexQn)     ]],
                      constant EBPhysicalParams & params             [[ buffer(EBComputeQnBufferIndexParams) ]],
                      threadgroup float4        * sharedPosition     [[ threadgroup(0)                       ]],
                      const uint                  threadInGrid       [[ thread_position_in_grid              ]],
                      const uint                  threadInGroup      [[ thread_position_in_threadgroup       ]],
                      const uint                  numThreadsInGroup  [[ threads_per_threadgroup              ]]) {
    // Get adjacent temperatures
    
    float4 curTemp = tn[threadInGrid];
    int x = (int)curTemp.x;
    int y = (int)curTemp.y;
    int z = (int)curTemp.z;
    float tside[6] = {0.f};
    
    if ((uint32_t)curTemp.x < params.numXElements-2) tside[north]=  tn[x+1+params.numXElements*(y   + params.numZElements*z)].w;
    if ((uint32_t)curTemp.x > 0)                     tside[south]=  tn[x-1+params.numXElements*(y   + params.numZElements*z)].w;
    if ((uint32_t)curTemp.y < params.numYElements-2) tside[east] =  tn[x+params.numXElements*  (y+1 + params.numZElements*z)].w;
    if ((uint32_t)curTemp.y > 0)                     tside[west] =  tn[x+params.numXElements*  (y-1 + params.numZElements*z)].w;
    if ((uint32_t)curTemp.z < params.numZElements-2) tside[top]  =  tn[x+params.numXElements*  (y   + params.numZElements*(z+1))].w;
    if ((uint32_t)curTemp.z > 0)                     tside[bottom] =tn[x+params.numXElements*  (y   + params.numZElements*(z-1))].w;
    qn[threadInGrid] = 0.f;
    
    for (int ii=0; ii<6;ii++) {
        
    }
}

kernel void ComputeTn1(device float4*              tn                 [[ buffer(EBComputeTnBufferIndexTn)       ]],
                       device float4*              heatFlow           [[ buffer(EBComputeTnBufferIndexHeatFlow) ]],
                       device float4*              tSup               [[ buffer(EBComputeTnBufferIndexTsup)     ]],
                       device float4*              tn1                [[ buffer(EBComputeTnBufferIndexTn1)      ]],
                       constant EBPhysicalParams & params             [[ buffer(EBComputeTnBufferIndexParams)   ]],
                       threadgroup float4        * sharedPosition     [[ threadgroup(0)                         ]],
                       const uint                  threadInGrid       [[ thread_position_in_grid                ]],
                       const uint                  threadInGroup      [[ thread_position_in_threadgroup         ]],
                       const uint                  numThreadsInGroup  [[ threads_per_threadgroup                ]]) {
    
}
