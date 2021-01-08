//
//  HeatTransferSimulation.m
//  HeatTransfer
//
//  Created by Eloi on 1/2/21.
//

#import "HeatTransferSimulation.h"
#import "HeatTransferKernelTypes.h"


@implementation HeatTransferSimulation {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLComputePipelineState> _computeQnPipeline;
    id<MTLComputePipelineState> _computeTn1Pipeline;

    NSUInteger _currentBufferIndex;
    
    id<MTLBuffer> _tn;
    id<MTLBuffer>  _temperatures[2];
    id<MTLBuffer>  _heatFlow;

    MTLSize _dispatchExecutionSizeQn;
    MTLSize _threadsPerThreadgroupQn;
    NSUInteger _threadgroupMemoryLengthQn;
    
    MTLSize _dispatchExecutionSizeTn1;
    MTLSize _threadsPerThreadgroupTn1;
    NSUInteger _threadgroupMemoryLengthTn1;

    // Indices into the _positions and _velocities array to track which buffer holds data for
    // the previous frame  and which holds the data for the new frame.
    uint8_t _tn1BufferIndex;
    uint8_t _tGuessBufferIndex;

    id<MTLBuffer> _simulationParams;
    
    // Current time of the simulation
    CFAbsoluteTime _simulationTime;
    
    int _bufferLength;
    
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

    id<MTLFunction> qnSimulator =  [defaultLibrary newFunctionWithName:@"ComputeQn"];
    id<MTLFunction> tn1Simulator = [defaultLibrary newFunctionWithName:@"ComputeTn1"];

    _computeQnPipeline = [_device newComputePipelineStateWithFunction:qnSimulator error:&error];
    if (!_computeQnPipeline) {
        NSLog(@"Failed to create Qn compute pipeline state, error %@", error);
    }
    
    _computeTn1Pipeline = [_device newComputePipelineStateWithFunction:tn1Simulator error:&error];
    if(!_computeTn1Pipeline) {
        NSLog(@"Failed to create Tn1 compute pipeline state, error %@", error);
    }
    _bufferLength = _config->numXElements * _config->numYElements * _config->numZElements;
    
    _threadsPerThreadgroupQn =  MTLSizeMake(_computeQnPipeline.threadExecutionWidth, 1, 1);
    _dispatchExecutionSizeQn =  MTLSizeMake(_bufferLength, 1, 1);
    _threadgroupMemoryLengthQn = _computeQnPipeline.threadExecutionWidth * sizeof(float);
    
    _threadsPerThreadgroupTn1 =  MTLSizeMake(_computeTn1Pipeline.threadExecutionWidth, 1, 1);
    _dispatchExecutionSizeTn1 =  MTLSizeMake(_bufferLength, 1, 1);
    _threadgroupMemoryLengthTn1 = _computeTn1Pipeline.threadExecutionWidth * sizeof(float);
    
    // Create Buffers
    NSUInteger bufferSize = sizeof(float) *  _bufferLength;

    _heatFlow =         [_device newBufferWithLength:bufferSize options:MTLResourceStorageModeManaged];
    _tn =               [_device newBufferWithLength:bufferSize options:MTLResourceStorageModeManaged];
    _simulationParams = [_device newBufferWithLength:sizeof(EBPhysicalParams) options:MTLResourceStorageModeManaged];
    
    _heatFlow.label =         @"Heat Flow ";
    _tn.label =               [NSString stringWithFormat:@"Temperature N"];
    _simulationParams.label = @"Simulation Params";
    
    for(int ii = 0; ii < 2; ii++) {
        _temperatures[ii] = [_device newBufferWithLength:bufferSize options:MTLResourceStorageModeManaged];
        _temperatures[ii].label = [NSString stringWithFormat:@"Temperature %i", ii];
    }
}

- (void)initializeData {
    _tn1BufferIndex = 1;
    _tGuessBufferIndex = 2;
    // Initialize temperatures and heat flows
    float *tn = (float *) _tn.contents;
    float *tn1 = (float *) _temperatures[_tn1BufferIndex].contents;
    float *tGuess = (float *) _temperatures[_tGuessBufferIndex].contents;
    float *heatFlows = (float *) _heatFlow.contents;
    
    
    for(int ii = 0; ii < _bufferLength; ii++) {
        // Flat[x + SIZE_X * (y + SIZE_Y * z)] = Original[x, y, z]
        tn[ii] = 0.f;
        tn1[ii]=0.f;
        tGuess[ii]=0.f;
        heatFlows[ii]=0.f;
    }
   /*
    for(int xx = 0; xx < _config->numXElements; xx++) {
        for(int yy = 0; yy < _config->numYElements; yy++) {
            for (int zz = 0; zz < _config->numZElements; zz++) {
                // Flat[x + SIZE_X * (y + SIZE_Y * z)] = Original[x, y, z]
                int idx = xx + _config->numXElements*(yy + _config->numYElements*zz);
                vector_float3 posn = getPosition(xx, yy, zz);
                
                tn[idx].xyz = posn;
                tn1[idx].xyz = posn;
                tGuess[idx].xyz = posn;
                heatFlows[idx].xyz = posn;
                
                tn[idx].w = _config->initialTemperature;
                tn1[idx].w = _config->initialTemperature;
                tGuess[idx].w = _config->initialTemperature;
                heatFlows[idx].w = 0.0;
            }
        }
    }
    */
    EBPhysicalParams *params = (EBPhysicalParams *)_simulationParams.contents;
    // Init simul params
    params->xLength = _config->xLength;
    params->yLength = _config->yLength;
    params->zLength = _config->zLength;
    params->numXElements = _config->numXElements;
    params->numYElements = _config->numYElements;
    params->numZElements = _config->numZElements;
    params->dX = _config->xLength/((float)_config->numXElements);
    params->dY = _config->yLength/((float)_config->numYElements);
    params->dZ = _config->zLength/((float)_config->numZElements);
    params->xArea = params->dY*params->dZ;
    params->yArea = params->dX*params->dZ;
    params->zArea = params->dX*params->dY;
    params->fluidTemperature = _config->fluidTemperature;
    params->deltaTime = _config->deltaTime;

    
    // Mark modified ranges
    [_simulationParams                  didModifyRange:NSMakeRange(0, _simulationParams.length)];
    [_tn                                didModifyRange:NSMakeRange(0, _tn.length)];
    [_temperatures[_tn1BufferIndex]     didModifyRange:NSMakeRange(0, _temperatures[_tn1BufferIndex].length)];
    [_temperatures[_tGuessBufferIndex]  didModifyRange:NSMakeRange(0, _temperatures[_tGuessBufferIndex].length)];
    [_heatFlow                          didModifyRange:NSMakeRange(0, _heatFlow.length)];
}


- (nonnull id<MTLBuffer>)computeQnWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer {
    [commandBuffer pushDebugGroup:@"Compute Qn"];
    // Increment time at start of computation
    _simulationTime += _config->deltaTime;
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    computeEncoder.label = @"Compute Qn Encoder";
    
    // Set Pipeline
    [computeEncoder setComputePipelineState:_computeQnPipeline];
    
    // Set Buffer
    [computeEncoder setBuffer:_tn                            offset:0 atIndex:EBComputeQnBufferIndexTn];
    [computeEncoder setBuffer:_heatFlow                      offset:0 atIndex:EBComputeQnBufferIndexQn];
    [computeEncoder setBuffer:_temperatures[_tn1BufferIndex] offset:0 atIndex:EBComputeQnBufferIndexTn1];
    [computeEncoder setBuffer:_simulationParams              offset:0 atIndex:EBComputeQnBufferIndexParams];

    // Params for this pipeline
    [computeEncoder setThreadgroupMemoryLength:_threadgroupMemoryLengthQn atIndex:0];
    [computeEncoder dispatchThreads:_dispatchExecutionSizeQn threadsPerThreadgroup:_threadsPerThreadgroupQn];
    [computeEncoder endEncoding];
    // Swap indexes
    uint8_t tn1Idx = _tn1BufferIndex;
    _tn1BufferIndex = _tGuessBufferIndex;
    _tGuessBufferIndex = tn1Idx;
    [commandBuffer popDebugGroup];
    return _heatFlow;
}


- (nonnull id<MTLBuffer>)computeTn1WithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
                                           recompute:(BOOL)recompute {
    [commandBuffer pushDebugGroup:@"Compute Tn1"];
    if (recompute) { // Swap indexes depending on recompute request
        uint8_t tGuessIdx = _tGuessBufferIndex;
        _tn1BufferIndex = _tGuessBufferIndex;
        _tGuessBufferIndex = tGuessIdx;
    }
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    computeEncoder.label = @"Compute Tn1 Encoder";

    // Set Pipeline
    [computeEncoder setComputePipelineState:_computeTn1Pipeline];
    
    // Set Buffer
    [computeEncoder setBuffer:_tn                               offset:0 atIndex:EBComputeTn1BufferIndexTn];
    [computeEncoder setBuffer:_heatFlow                         offset:0 atIndex:EBComputeTn1BufferIndexQn];
    [computeEncoder setBuffer:_temperatures[_tGuessBufferIndex] offset:0 atIndex:EBComputeTn1BufferIndexTguess];
    [computeEncoder setBuffer:_temperatures[_tn1BufferIndex]    offset:0 atIndex:EBComputeTn1BufferIndexTn1];
    [computeEncoder setBuffer:_simulationParams                 offset:0 atIndex:EBComputeTn1BufferIndexParams];

    // Params for this pipeline
    [computeEncoder setThreadgroupMemoryLength:_threadgroupMemoryLengthTn1 atIndex:0];
    [computeEncoder dispatchThreads:_dispatchExecutionSizeTn1 threadsPerThreadgroup:_threadsPerThreadgroupTn1];
    [computeEncoder endEncoding];
    
    [commandBuffer popDebugGroup];
    
    return _temperatures[_tn1BufferIndex];
}

@end
