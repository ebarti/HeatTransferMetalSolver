//
//  HeatTransferSimulation.h
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>


typedef struct EBSimulationConfig
{
    float xLength;
    float yLength;
    float zLength;
    uint32_t numXElements;
    uint32_t numYElements;
    uint32_t numZElements;
    float fluidTemperature;
    float initialTemperature;
    float deltaTime;
    float maxTime;
} EBSimulationConfig;

NS_ASSUME_NONNULL_BEGIN

@interface HeatTransferSimulation : NSObject

- (instancetype)initWithComputeDevice:(id<MTLDevice>)computeDevice
                                       config:(const EBSimulationConfig *)config;

- (void)computeQnWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;
- (id<MTLBuffer>)computeTn1WithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                   recompute:(BOOL)recompute;


@end

NS_ASSUME_NONNULL_END
