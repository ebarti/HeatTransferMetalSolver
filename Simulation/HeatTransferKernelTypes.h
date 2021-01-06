//
//  HeatTransferKernelTypes.h
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#ifndef HeatTransferKernelTypes_h
#define HeatTransferKernelTypes_h

#include <simd/simd.h>

typedef enum EBComputeQnBufferIndex
{
    EBComputeQnBufferIndexTn = 0,
    EBComputeQnBufferIndexQn = 1,
    EBComputeQnBufferIndexParams = 2
} EBComputeQnBufferIndex;


typedef enum EBComputeTn1BufferIndex
{
    EBComputeTnBufferIndexTn = 0,
    EBComputeTnBufferIndexHeatFlow = 1,
    EBComputeTnBufferIndexTsup = 2,
    EBComputeTnBufferIndexTn1 = 3,
    EBComputeTnBufferIndexParams = 4
} EBComputeTn1BufferIndex;

typedef struct EBPhysicalParams
{
    float xLength;
    float yLength;
    float zLength;
    float dX;
    float dY;
    float dZ;
    float xArea;
    float yArea;
    float zArea;
    uint32_t numXElements;
    uint32_t numYElements;
    uint32_t numZElements;
    float beta;
    float rho;
    float fluidTemperature;
    float deltaTime;
    // TODO: add parameters for a dynamic physical model instead of the current hard coded model within the kernel computation.
} EBPhysicalParams;

#endif /* HeatTransferKernelTypes_h */
