//
//  ViewController.m
//  HeatTransfer
//
//  Created by Eloi on 12/29/20.
//

#import "ViewController.h"
#import "HeatTransferRenderer.h"
#import "HeatTransferSimulation.h"
#import <QuartzCore/CAMetalLayer.h>
@import Accelerate;

static const EBSimulationConfig HeatTransferConfigs[] =
{
    //xLength yLength zLength numXElements numYElements numZElements fluidTemp initialTemp deltaTime maxTime
      {0.25,    0.25,   0.25,       64,        64,        64,         300,        1273,      0.1,      200},
};

@implementation ViewController {
    MTKView *_view;
    HeatTransferRenderer* _renderer;
    HeatTransferSimulation* _simulator;
    id<MTLDevice> _device;
    
    CFAbsoluteTime _simulationTime;
    const EBSimulationConfig* _config;
    
    id<MTLCommandQueue> _commandQueue;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Create device
    NSArray<id<MTLDevice>> * availableDevices = nil;

    // Query all supported metal devices with observer so app can get external device add/remove notifications
    availableDevices = MTLCopyAllDevices();


    if(availableDevices == nil || ([availableDevices count] == 0))
    {
        assert(!"Metal is not supported on this Mac");
        self.view = [[NSView alloc] initWithFrame:self.view.frame];
        return;
    }
    for(id<MTLDevice> device in availableDevices)
    {
        if(device.isRemovable || device.isHeadless)
        {
            _device = device;
            break;
        }
    }
    if(nil == _device) {
        assert(!"Could not find EGPU");
        self.view = [[NSView alloc] initWithFrame:self.view.frame];
        return;
    }
    
    NSLog(@"Selected compute device: %@", _device.name);
    // Set device to view
    CGDirectDisplayID viewDisplayID = (CGDirectDisplayID) [_view.window.screen.deviceDescription[@"NSScreenNumber"] unsignedIntegerValue];
    
    id<MTLDevice> rendererDevice = CGDirectDisplayCopyCurrentMetalDevice(viewDisplayID);

    if(rendererDevice != _view.device) {
        assert(!"I wanted both compute and render on the same EGPU...");
        self.view = [[NSView alloc] initWithFrame:self.view.frame];
        return;
    }
    
}


- (void)viewDidAppear
{
    [self startSimulation];
}

- (void) startSimulation {
    _simulationTime = 0;

    _config = &HeatTransferConfigs[0];
    
    _simulator = [[HeatTransferSimulation alloc] initWithComputeDevice:_device
                                                                config:_config];

    [_renderer setRenderScale:1 withDrawableSize:_view.drawableSize];
    
    _commandQueue = [_renderer.device newCommandQueue];
}

- (void)viewDidDisappear
{
}

- (void)drawInMTKView:(nonnull MTKView *)view {
   
    if(_simulationTime >= _config->maxTime) {
        return;
    }
    // Create a command buffer to both execute a simulation frame and render an update
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    [commandBuffer pushDebugGroup:@"Controller Frame"];
    
    // Render first then simulate
    

    // Simulate the frame and obtain the new positions for the update.  If this is the final
    // frame positionBuffer will be filled with the all positions used for the simulation
    [_simulator computeQnWithCommandBuffer:commandBuffer];
    id<MTLBuffer> tempBuffer = [_simulator computeTn1WithCommandBuffer:commandBuffer recompute:NO];
    
    
    // TODO: IN THE WORKS
    
    
    // Render the updated positions (or all positions in the case that the simulation is complete)
    /*[_renderer drawWithCommandBuffer:commandBuffer
                     positionsBuffer:positionBuffer
                           numBodies:numBodies
                              inView:_view];
     */

    [commandBuffer commit];

    [commandBuffer popDebugGroup];

    _simulationTime += _config->deltaTime;
}


- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    [_renderer drawableSizeWillChange:size];;
}

- (BOOL)commitEditingAndReturnError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    return;
}




@end
