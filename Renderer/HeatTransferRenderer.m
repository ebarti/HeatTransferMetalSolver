//
//  HeatTransferRenderer.m
//  HeatTransfer
//
//  Created by Eloi on 12/30/20.
//


#import "HeatTransferShaders.metal"
#import "HeatTransferRenderer.h"

@implementation HeatTransferRenderer {
    // renderer global ivars
    id <MTLDevice>              _device;
    id <MTLCommandQueue>        _cmdQueue;
    id <MTLRenderPipelineState> _pipelineState;


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

        _drawableRenderDescriptor = [MTLRenderPassDescriptor new];
        _drawableRenderDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _drawableRenderDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _drawableRenderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 1, 1);
        
        id<MTLLibrary> shaderLib = [_device newDefaultLibrary];
        if(!shaderLib)
        {
            NSLog(@" ERROR: Couldnt create a default shader library");
            // assert here because if the shader libary isn't loading, nothing good will happen
            return nil;
        }

        id <MTLFunction> vertexProgram = [shaderLib newFunctionWithName:@"vertexShader"];
        if(!vertexProgram)
        {
            NSLog(@">> ERROR: Couldn't load vertex function from default library");
            return nil;
        }

        id <MTLFunction> fragmentProgram = [shaderLib newFunctionWithName:@"fragmentShader"];
        if(!fragmentProgram)
        {
            NSLog(@" ERROR: Couldn't load fragment function from default library");
            return nil;
        }

        /// CREATE PIPELINE
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];

        pipelineDescriptor.label                           = @"HeatTransferPipeline";
        pipelineDescriptor.vertexFunction                  = vertexProgram;
        pipelineDescriptor.fragmentFunction                = fragmentProgram;


        NSError *error;
        /// STORE THE PIPELINE'S STATE
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                 error:&error];
        if(!_pipelineState)
        {
            NSLog(@"ERROR: Failed aquiring pipeline state: %@", error);
            return nil;
        }
    }
    return self;
}

- (void)renderToMetalLayer:(nonnull CAMetalLayer*)metalLayer {
    _frameNum++;
    
    // Create buffer
    id <MTLCommandBuffer> commandBuffer = [_cmdQueue commandBuffer];

    // Get what we're drawing on!
    id<CAMetalDrawable> actualDrawable = [metalLayer nextDrawable];

    if(!actualDrawable) {
        return;
    }

    id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_drawableRenderDescriptor];

    [renderEncoder setRenderPipelineState:_pipelineState];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:actualDrawable];

    [commandBuffer commit];
}

- (void)drawableResize:(CGSize)drawableSize {
    
}


@end
