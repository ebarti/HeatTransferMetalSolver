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
    north = 1,
    south = 2,
    east = 3,
    west = 4,
    top = 5,
    bottom = 6
} HeatTransferDirection;

static float cp(const float4 posn) {
    return 467.6;
}

static float lambda(const float4 posn) {
    float l = 29.0;
    if (posn.w < 1273.0) {
        l += (1273.0-posn.w)/900.0 + 29;
    }
    return l;
}

kernel void ComputeQn(device float4*              newTemperature     [[ buffer(EBComputeBufferIndexNewTemperature) ]],
                                 device float4*              newHeatFlow        [[ buffer(EBComputeBufferIndexNewHeatFlow)    ]],
                                 device float4*              oldTemperature     [[ buffer(EBComputeBufferIndexOldTemperature) ]],
                                 device float4*              oldHeatFlow        [[ buffer(EBComputeBufferIndexOldHeatFlow)    ]],
                                 constant EBPhysicalParams & params             [[ buffer(EBComputeBufferIndexPhysicalParams) ]],
                                 threadgroup float4        * sharedPosition     [[ threadgroup(0)                             ]],
                                 const uint                  threadInGrid       [[ thread_position_in_grid                    ]],
                                 const uint                  threadInGroup      [[ thread_position_in_threadgroup             ]],
                                 const uint                  numThreadsInGroup  [[ threads_per_threadgroup                    ]]) {
    
}

kernel void ComputeTn1(device float4*              newTemperature     [[ buffer(EBComputeBufferIndexNewTemperature) ]],
                                 device float4*              newHeatFlow        [[ buffer(EBComputeBufferIndexNewHeatFlow)    ]],
                                 device float4*              oldTemperature     [[ buffer(EBComputeBufferIndexOldTemperature) ]],
                                 device float4*              oldHeatFlow        [[ buffer(EBComputeBufferIndexOldHeatFlow)    ]],
                                 constant EBPhysicalParams & params             [[ buffer(EBComputeBufferIndexPhysicalParams) ]],
                                 threadgroup float4        * sharedPosition     [[ threadgroup(0)                             ]],
                                 const uint                  threadInGrid       [[ thread_position_in_grid                    ]],
                                 const uint                  threadInGroup      [[ thread_position_in_threadgroup             ]],
                                 const uint                  numThreadsInGroup  [[ threads_per_threadgroup                    ]]) {
    
}
