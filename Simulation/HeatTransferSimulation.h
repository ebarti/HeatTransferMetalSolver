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
    float initialTemperature;
    float fluidTemperature;
    float deltaTime;
    float maxTime;
} EBSimulationConfig;

NS_ASSUME_NONNULL_BEGIN

@interface HeatTransferSimulation : NSObject

- (instancetype)initWithComputeDevice:(id<MTLDevice>)computeDevice
                                       config:(const EBSimulationConfig *)config;

- (id<MTLBuffer>)simulateFrameWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer;


@end

NS_ASSUME_NONNULL_END
