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
    EBComputeQnBufferIndexTn1 = 2,
    EBComputeQnBufferIndexParams = 3
} EBComputeQnBufferIndex;


typedef enum EBComputeTn1BufferIndex
{
    EBComputeTn1BufferIndexTn = 0,
    EBComputeTn1BufferIndexQn = 1,
    EBComputeTn1BufferIndexTguess = 2,
    EBComputeTn1BufferIndexTn1 = 3,
    EBComputeTn1BufferIndexParams = 4
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
