//
//  HeatTransferSimulation.m
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#import "HeatTransferSimulation.h"
#import "HeatTransferKernelTypes.h"

static const NSUInteger CountUpdateBuffersStored = 3;

@implementation HeatTransferSimulation {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLComputePipelineState> _computePipeline;
    id<MTLBuffer> _updateBuffer[CountUpdateBuffersStored];

    NSData *_updateData[CountUpdateBuffersStored];

    NSUInteger _currentBufferIndex;

    id<MTLBuffer>  _temperatures[2];
    id<MTLBuffer>  _heatFlows[2];

    MTLSize _dispatchExecutionSize;
    MTLSize _threadsPerThreadgroup;
    NSUInteger _threadgroupMemoryLength;

    // Indices into the _positions and _velocities array to track which buffer holds data for
    // the previous frame  and which holds the data for the new frame.
    uint8_t _oldBufferIndex;
    uint8_t _newBufferIndex;

    id<MTLBuffer> _simulationParams;

    // Current time of the simulation
    CFAbsoluteTime _simulationTime;

    const EBSimulationConfig  * _config;
}

- (nonnull instancetype)initWithComputeDevice:(nonnull id<MTLDevice>)computeDevice config:(nonnull const EBSimulationConfig *)config { 
    self = [super init];

    if(self)
    {
        _device = computeDevice;

        _config = config;

        [self createMetalObjectsAndMemory];

        [self initializeData];
    }

    return self;
}

- (nonnull id<MTLBuffer>)simulateFrameWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer { 
    <#code#>;
}

- (void)createMetalObjectsAndMemory {
    // Get Metal library
    NSError *error = nil;

    // Load all the shader files with a .metal file extension in the project
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    id<MTLFunction> heatSimulator = [defaultLibrary newFunctionWithName:@":TODO"];

    _computePipeline = [_device newComputePipelineStateWithFunction:heatSimulator error:&error];
    if (!_computePipeline)
    {
        NSLog(@"Failed to create compute pipeline state, error %@", error);
    }
    
}

- (void)initializeData {
    
}


@end
