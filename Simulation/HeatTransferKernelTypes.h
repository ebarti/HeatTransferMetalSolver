//
//  HeatTransferKernelTypes.h
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#ifndef HeatTransferKernelTypes_h
#define HeatTransferKernelTypes_h

#include <simd/simd.h>

typedef enum EBComputeBufferIndex
{
    EBComputeBufferIndexOldTemperature = 0,
    EBComputeBufferIndexOldHeatFlow = 1,
    EBComputeBufferIndexNewTemperature = 2,
    EBComputeBufferIndexNewHeatFlow = 3,
    EBComputeBufferIndexPhysicalParams = 4
} EBComputeBufferIndex;

typedef struct EBPhysicalParams
{
    float xLength;
    float yLength;
    float zLength;
    uint32_t numXElements;
    uint32_t numYElements;
    uint32_t numZElements;
    float fluidTemperature;
    float deltaTime;
    // TODO: add parameters for a dynamic physical model instead of the current hard coded model within the kernel computation.
} EBPhysicalParams;

#endif /* HeatTransferKernelTypes_h */
