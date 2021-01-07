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


@implementation ViewController {
    HeatTransferRenderer* _renderer;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Create device
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();


}


- (void)drawInMTKView:(nonnull MTKView *)view {
    return;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    return;
}

- (BOOL)commitEditingAndReturnError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    return;
}

@end
