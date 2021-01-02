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

kernel void SimulateHeatTransfer(device float4*              newTemperature     [[ buffer(EBComputeBufferIndexNewTemperature) ]],
                                 device float4*              newHeatFlow        [[ buffer(EBComputeBufferIndexNewHeatFlow)    ]],
                                 device float4*              oldTemperature     [[ buffer(EBComputeBufferIndexOldTemperature) ]],
                                 device float4*              oldHeatFlow        [[ buffer(EBComputeBufferIndexOldHeatFlow)    ]],
                                 constant EBPhysicalParams & params             [[ buffer(EBComputeBufferIndexPhysicalParams) ]],
                                 threadgroup float4        * sharedPosition     [[ threadgroup(0)                             ]],
                                 const uint                  threadInGrid       [[ thread_position_in_grid                    ]],
                                 const uint                  threadInGroup      [[ thread_position_in_threadgroup             ]],
                                 const uint                  numThreadsInGroup  [[ threads_per_threadgroup                    ]]) {
    
}
