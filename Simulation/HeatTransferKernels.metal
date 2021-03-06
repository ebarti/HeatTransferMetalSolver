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
static float A(const float t, const float tside, HeatTransferDirection direction, const EBPhysicalParams params){
    if (0 == tside) return 0.f;
    float d = params.dX;
    float area = params.xArea;
     if (east == direction || west == direction) {
         d = params.dY;
         area = params.yArea;
    } else if (top == direction || bottom == direction){
        d = params.dZ;
        area = params.zArea;
    }
    return (lambda(t) + lambda(tside)) * params.yArea / (2.f * d);
}

static float getSurfaceArea(const uint32_t x, const uint32_t y, const uint32_t z, const EBPhysicalParams params) {
    float Area = 0.0;
    if (x == 0 || x == (params.numXElements-1))
        Area += params.xArea;
    if (y == 0 || y == (params.numXElements-1))
        Area += params.yArea;
    if (z == 0 || z == (params.numXElements-1))
        Area += params.zArea;
    return Area;
}

static float alpha(const float temp) {
    return -5561.455 + 53.22458*temp - 0.1940006*pow(temp,2.0) + 0.0003336*pow(temp,3.0) - 2.548565e-7*pow(temp,4.0) + 6.988594e-11*pow(temp,5.0);
}

static void getxyz(const uint32_t threadInGrid, thread uint32_t * x, thread uint32_t * y, thread uint32_t * z, const EBPhysicalParams params) {
    uint32_t posn = threadInGrid;
    *x = posn % params.numXElements;
    // (idx - x) / SIZE_X = +  * (y + SIZE_Y * z)
    posn -= *x;
    posn /= params.numXElements;
    // (idx - x) / SIZE_X = posn = y + SIZE_Y * z
    *y = posn % params.numYElements;
    posn -= *y;
    posn /= params.numYElements;
    // (posn  - y)/SIZE_Y = z
    *z = posn;
}


// We also use this cmpute kernel to copy values from Tn1 to Tn - Qn is calculated only based off Tn.
kernel void ComputeQn(device float*               tn           [[ buffer(EBComputeQnBufferIndexTn)     ]],
                      device float*               qn           [[ buffer(EBComputeQnBufferIndexQn)     ]],
                      device float*               tn1          [[ buffer(EBComputeQnBufferIndexTn1)    ]],
                      constant EBPhysicalParams & params       [[ buffer(EBComputeQnBufferIndexParams) ]],
                      const uint                  threadInGrid [[ thread_position_in_grid              ]]) {
    uint32_t x, y, z;
    x = y = z = 0;
    getxyz(threadInGrid, &x, &y, &z, params);
    
    float temp = tn1[threadInGrid];

    float tside[6] = {0.f};
    float newQn = 0.f;
    if (x < params.numXElements-1) tside[north]=  tn[x+1+params.numXElements*(y   + params.numZElements*z)];
    if (x > 0)                     tside[south]=  tn[x-1+params.numXElements*(y   + params.numZElements*z)];
    if (y < params.numYElements-1) tside[east] =  tn[x+params.numXElements*  (y+1 + params.numZElements*z)];
    if (y > 0)                     tside[west] =  tn[x+params.numXElements*  (y-1 + params.numZElements*z)];
    if (z < params.numZElements-1) tside[top]  =  tn[x+params.numXElements*  (y   + params.numZElements*(z+1))];
    if (z > 0)                     tside[bottom] =tn[x+params.numXElements*  (y   + params.numZElements*(z-1))];
    
    
    for (int ii=0; ii<6;ii++) {
        newQn += A(temp, tside[ii], (HeatTransferDirection)ii, params) * (tside[ii] - temp);
    }
    // Boundary condition Qn
    newQn += alpha(temp) * getSurfaceArea(x, y, z, params) * (params.fluidTemperature-temp);
    qn[threadInGrid] = newQn;
    // COPY TN1 to TN
    tn[threadInGrid] = temp;
}

kernel void ComputeTn1(device float*               tn           [[ buffer(EBComputeTn1BufferIndexTn)       ]],
                       device float*               qn           [[ buffer(EBComputeTn1BufferIndexQn)       ]],
                       device float*               tGuess       [[ buffer(EBComputeTn1BufferIndexTguess)   ]],
                       device float*               tn1          [[ buffer(EBComputeTn1BufferIndexTn1)      ]],
                       constant EBPhysicalParams & params       [[ buffer(EBComputeTn1BufferIndexParams)   ]],
                       const uint                  threadInGrid [[ thread_position_in_grid                 ]]) {
    uint32_t x, y, z;
    x = y = z = 0;
    getxyz(threadInGrid, &x, &y, &z, params);
    
    float temp_n = tn[threadInGrid];
    float temp_guess = tGuess[threadInGrid];
    float temp = tn1[threadInGrid];

    float tside[6] = {0.f};
    if (x < params.numXElements-1) tside[north]=  tGuess[x+1+params.numXElements*(y   + params.numZElements*z)];
    if (x > 0)                     tside[south]=  tGuess[x-1+params.numXElements*(y   + params.numZElements*z)];
    if (y < params.numYElements-1) tside[east] =  tGuess[x+params.numXElements*  (y+1 + params.numZElements*z)];
    if (y > 0)                     tside[west] =  tGuess[x+params.numXElements*  (y-1 + params.numZElements*z)];
    if (z < params.numZElements-1) tside[top]  =  tGuess[x+params.numXElements*  (y   + params.numZElements*(z+1))];
    if (z > 0)                     tside[bottom] =tGuess[x+params.numXElements*  (y   + params.numZElements*(z-1))];
    
    float surfaceArea = getSurfaceArea(x, y, z, params);
    float AiTi = 0.f;
    float Ap = 0.f;
    float Bp = (1 - params.beta) * qn[threadInGrid] + (temp_n * params.rho * params.dX * params.dY * params.dZ) / params.deltaTime ;
    // boundary condition Bp
    Bp += params.beta * alpha(temp_guess)*surfaceArea;
    
    // Build AiTi and Ap
    for (int ii=0; ii<6;ii++) {
        float A_side = A(temp, tside[ii], (HeatTransferDirection)ii, params);
        AiTi +=  A_side * tside[ii];
        Ap += A_side;
    }
    AiTi *= params.beta;
    Ap *= params.beta;
    // Boundary condition Ap
    Ap += params.beta * alpha(temp_guess) * params.fluidTemperature * surfaceArea;
    tn1[threadInGrid] = (AiTi + Bp) / Ap;
}

