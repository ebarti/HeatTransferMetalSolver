//
//  HeatTransferSimulation.m
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#import "HeatTransferSimulation.h"
#import "HeatTransferKernelTypes.h"

static const NSUInteger CountUpdateBuffersStored = 3;

static vector_float3 getPosition(int x, int y, int z) {
    vector_float3 v = {0.0, 0.0, 0.0};
    
    // Remap accordingly in shader
    v.x = ((float)x);
    v.y = ((float)y);
    v.z = ((float)z);
    return v;
}

@implementation HeatTransferSimulation {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLComputePipelineState> _computeQnPipeline;
    id<MTLComputePipelineState> _computeTn1Pipeline;

    NSUInteger _currentBufferIndex;

    id<MTLBuffer>  _temperatures[2];
    id<MTLBuffer>  _heatFlows[2];

    MTLSize _dispatchExecutionSizeQn;
    MTLSize _threadsPerThreadgroupQn;
    NSUInteger _threadgroupMemoryLengthQn;
    
    MTLSize _dispatchExecutionSizeTn1;
    MTLSize _threadsPerThreadgroupTn1;
    NSUInteger _threadgroupMemoryLengthTn1;

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

- (void)createMetalObjectsAndMemory {
    // Get Metal library
    NSError *error = nil;

    // Load all the shader files with a .metal file extension in the project
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    id<MTLFunction> qnSimulator = [defaultLibrary newFunctionWithName:@"ComputeQn"];
    
    id<MTLFunction> tn1Simulator = [defaultLibrary newFunctionWithName:@"ComputeTn1"];

    _computeQnPipeline = [_device newComputePipelineStateWithFunction:qnSimulator error:&error];
    if (!_computeQnPipeline) {
        NSLog(@"Failed to create Qn compute pipeline state, error %@", error);
    }
    
    _computeTn1Pipeline = [_device newComputePipelineStateWithFunction:tn1Simulator error:&error];
    if(!_computeTn1Pipeline) {
        NSLog(@"Failed to create Tn1 compute pipeline state, error %@", error);
    }
    uint32_t totalSize = _config->numXElements * _config->numYElements * _config->numZElements;
    
    _threadsPerThreadgroupQn = MTLSizeMake(_computeQnPipeline.threadExecutionWidth, 1, 1);
    _dispatchExecutionSizeQn =  MTLSizeMake(totalSize, 1, 1);
    _threadgroupMemoryLengthQn = _computeQnPipeline.threadExecutionWidth * sizeof(vector_float4);
    
    _threadsPerThreadgroupTn1 = MTLSizeMake(_computeTn1Pipeline.threadExecutionWidth, 1, 1);
    _dispatchExecutionSizeTn1 =  MTLSizeMake(totalSize, 1, 1);
    _threadgroupMemoryLengthTn1 = _computeTn1Pipeline.threadExecutionWidth * sizeof(vector_float4);
    
    // Create Buffers
    NSUInteger bufferSize = sizeof(vector_float3) *  totalSize;
    // Create 2 buffers for both positions and velocities since we'll need to preserve previous
    // frames data while computing the next frame
    for(int ii = 0; ii < CountUpdateBuffersStored; ii++) {
        _temperatures[ii] = [_device newBufferWithLength:bufferSize options:MTLResourceStorageModeManaged];
        _heatFlows[ii] = [_device newBufferWithLength:bufferSize options:MTLResourceStorageModeManaged];

        _temperatures[ii].label = [NSString stringWithFormat:@"Temperatures %i", ii];
        _heatFlows[ii].label = [NSString stringWithFormat:@"Heat Flow %i", ii];
    }
    
    _simulationParams = [_device newBufferWithLength:sizeof(EBPhysicalParams) options:MTLResourceStorageModeManaged];

    _simulationParams.label = @"Simulation Params";

    EBPhysicalParams *params = (EBPhysicalParams *)_simulationParams.contents;

    params->xLength = _config->xLength;
    params->yLength = _config->yLength;
    params->zLength = _config->zLength;
    params->numXElements = _config->numXElements;
    params->numYElements = _config->numYElements;
    params->numZElements = _config->numZElements;
    params->dX = _config->xLength/((float)_config->numXElements);
    params->dY = _config->yLength/((float)_config->numYElements);
    params->dZ = _config->zLength/((float)_config->numZElements);
    params->fluidTemperature = _config->fluidTemperature;
    params->deltaTime = _config->deltaTime;

    [_simulationParams didModifyRange:NSMakeRange(0, _simulationParams.length)];
}

- (void)initializeData {
    _oldBufferIndex = 0;
    _newBufferIndex = 1;
    
    // Initialize temperatures and heat flows
    vector_float4 *temperatures = (vector_float4 *) _temperatures[_oldBufferIndex].contents;
    vector_float4 *heatFlows = (vector_float4 *) _heatFlows[_oldBufferIndex].contents;
    for(int xx = 0; xx < _config->numXElements; xx++) {
        for(int yy = 0; yy < _config->numYElements; yy++) {
            for (int zz = 0; zz < _config->numZElements; zz++) {
                // Flat[x + SIZE_X * (y + SIZE_Y * z)] = Original[x, y, z]
                int idx = xx + _config->numXElements*(yy + _config->numYElements*zz);
                temperatures[idx].xyz = getPosition(xx,yy,zz);
                temperatures[idx].w = _config->initialTemperature;
                heatFlows[idx].xyz = getPosition(xx,yy,zz);
                heatFlows[idx].w = 0.0;
            }
        }
    }
    // Mark modified ranges
    [_temperatures[_oldBufferIndex] didModifyRange:NSMakeRange(0, _temperatures[_oldBufferIndex].length)];
    [_heatFlows[_oldBufferIndex] didModifyRange:NSMakeRange(0, _heatFlows[_oldBufferIndex].length)];
}


- (nonnull id<MTLBuffer>)computeQnWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer {
    [commandBuffer pushDebugGroup:@"Compute Qn"];
    
    
    [commandBuffer popDebugGroup];
    return nil;
}


- (nonnull id<MTLBuffer>)computeTn1WithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer {
    [commandBuffer pushDebugGroup:@"Compute Tn1"];
    
    
    [commandBuffer popDebugGroup];
    return nil;
}

@end
