//
//  HeatTransferRenderer.m
//  HeatTransfer
//
//  Created by Eloi on 12/30/20.
//

#include <simd/simd.h>
#import "HeatTransferRenderer.h"

@implementation HeatTransferRenderer {
    // renderer global ivars
    id <MTLDevice>              _device;
    id <MTLCommandQueue>        _cmdQueue;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLBuffer>              _vertices;
    id <MTLTexture>             _depthTarget;

    // Render pass descriptor which creates a render command encoder to draw to the drawable
    // textures
    MTLRenderPassDescriptor *_drawableRenderDescriptor;

    vector_uint2 _viewportSize;
    
    NSUInteger _frameNum;
}


- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device {
    self = [super init];
    if (self) {
        _frameNum = 0;
        _device = device;
        _cmdQueue = [_device newCommandQueue];
        
    }
    return self;
}

- (void)renderToMetalLayer:(nonnull CAMetalLayer*)metalLayer {
    
}

- (void)drawableResize:(CGSize)drawableSize {
    
}


@end
