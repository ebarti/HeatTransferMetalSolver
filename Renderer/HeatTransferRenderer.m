//
//  HeatTransferRenderer.m
//  HeatTransfer
//
//  Created by Eloi on 1/7/21.
//
@import simd;
@import MetalKit;
#import <stdlib.h>

#import "HeatTransferRenderer.h"
#import "HeatTransferShaderTypes.h"
#import "HeatTransferSimulation.h"

static const NSUInteger MaxRenderBuffersInFlight = 3;

// Size of gaussian map to create rounded smooth points
static const NSUInteger AAPLGaussianMapSize = 64;

@implementation HeatTransferRenderer {
    dispatch_semaphore_t _inFlightSemaphore;
    
    id<MTLTexture> _texture;

    id<MTLBuffer> _colors;

    // Metal objects
    id<MTLBuffer> _positionsBuffer;
    id<MTLBuffer> _dynamicUniformBuffers[MaxRenderBuffersInFlight];
    id<MTLRenderPipelineState> _renderPipeline;
    id<MTLDepthStencilState> _depthState;

    // Current buffer to fill with dynamic uniform data and set for the current frame
    uint8_t _currentBufferIndex;

    // Projection matrix calculated as a function of view size
    matrix_float4x4 _projectionMatrix;
    
    const EBSimulationConfig  * _config;
    
    float _renderScale;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView {
    self = [super init];
    if(self)
    {
        _device = mtkView.device;

        _inFlightSemaphore = dispatch_semaphore_create(MaxRenderBuffersInFlight);
        [self loadMetal:mtkView];
        [self generateGaussianMap];
    }

    return self;
}

-(void) generateGaussianMap
{
    NSError *error;

    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];

    textureDescriptor.textureType = MTLTextureType3D;
    textureDescriptor.pixelFormat = MTLPixelFormatR8Unorm;
    textureDescriptor.width = AAPLGaussianMapSize;
    textureDescriptor.height = AAPLGaussianMapSize;
    textureDescriptor.mipmapLevelCount = 1;
    textureDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;
    textureDescriptor.usage = MTLTextureUsageShaderRead;

    _texture = [_device newTextureWithDescriptor:textureDescriptor];

    // Calculate the size of a RGBA8Unorm texture's data and allocate system memory buffer
    // used to fill the texture's memory
    NSUInteger dataSize = textureDescriptor.width  * textureDescriptor.height * textureDescriptor.depth  * sizeof(uint8_t);
    
    const vector_float3 nDelta = { 2.0 / (float)textureDescriptor.width, 2.0 /(float) textureDescriptor.height,  2.0 /(float) textureDescriptor.depth};

    uint8_t* texelData = (uint8_t*) malloc(dataSize);
    uint8_t* texel = texelData;

    vector_float3 SNormCoordinate = -1.0;

    int i = 0;

    // Procedurally generate data to fill the texture's buffer
    for(uint32_t z = 0; z < textureDescriptor.depth; z++) {
        SNormCoordinate.z = -1.0 + z * nDelta.z;
        for(uint32_t y = 0; y < textureDescriptor.height; y++) {
            SNormCoordinate.y = -1.0 + y * nDelta.y;
            for(uint32_t x = 0; x < textureDescriptor.width; x++) {
                SNormCoordinate.x = -1.0 + x * nDelta.x;

                float distance = vector_length(SNormCoordinate);
                float t = (distance  < 1.0f) ? distance : 1.0f;

                // Hermite interpolation where u = {1, 0} and v = {0, 0}
                float color = ((2.0f * t - 3.0f) * t * t + 1.0f);

                texel[i] = 0xFF * color;

                i++;
            }
        }
    }
    

    free(texelData);

    MTLRegion region = {{ 0, 0, 0 }, {textureDescriptor.width, textureDescriptor.height, textureDescriptor.depth}};

    [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:texelData
                    bytesPerRow:sizeof(uint8_t) * textureDescriptor.width];

    if(!_texture || error)
    {
        NSLog(@"Error creating gaussian map: %@", error.localizedDescription);
    }

    _texture.label = @"Gaussian Map";
}

- (void)updateProjection:(CGSize)size
{
    // React to resize of the draw rect.  In particular update the perspective matrix.
    // Update the aspect ratio and projection matrix since the view orientation or size has changed
    const float aspect = (float)size.height / size.width;
    const float left   = _renderScale;
    const float right  = -_renderScale;
    const float bottom = _renderScale * aspect;
    const float top    = -_renderScale * aspect;
    const float near   = 5000;
    const float far    = -5000;
    
    
    matrix_float4x4 proj = (matrix_float4x4){{2 / (right - left), 0,                  0,                 (left + right) / (left - right),
                                              0,                  2 / (top - bottom), 0,                 (top + bottom) / (bottom - top),
                                              0,                  0,                  1 / (far - near),  near / (near - far),
                                              0,                  0,                  0,                 1 }};
    _projectionMatrix = proj;
}

- (void)drawableSizeWillChange:(CGSize)size { 
    [self updateProjection:size];;
}

/// Update any render state (including updating dynamically changing Metal buffers)
- (void)updateState
{
    EBUniforms *uniforms = (EBUniforms *)_dynamicUniformBuffers[_currentBufferIndex].contents;

    uniforms->mvpMatrix = _projectionMatrix;
}

- (void)drawWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer positionsBuffer:(nonnull id<MTLBuffer>)temperatureBuffer numXElements:(NSUInteger)numXElements numYElements:(NSUInteger)numYElements numZElements:(NSUInteger)numZElements inView:(nonnull MTKView *)view {
    // Wait to ensure only AAPLMaxRenderBuffersInFlight are getting processed by any stage in the Metal
    // pipeline (App, Metal, Drivers, GPU, etc)
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    [commandBuffer pushDebugGroup:@"Draw Simulation Data"];

    // Add completion hander which signals _inFlightSemaphore when Metal and the GPU has fully
    // finished processing the commands encoded this frame.  This indicates when the dynamic
    // buffers, written to this frame, will no longer be needed by Metal and the GPU, meaning the
    // buffer contents can be changed without corrupting rendering
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];


    [self updateState];

    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    // If a renderPassDescriptor has been obtained, render to the drawable, otherwise skip
    // any rendering this frame because there is no drawable to draw to
    if(renderPassDescriptor != nil)
    {
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        renderEncoder.label = @"Render Commands";

        [renderEncoder setRenderPipelineState:_renderPipeline];

        if(temperatureBuffer)
        {
            // Synchronize since positions buffer may be created on another thread
            @synchronized(self)
            {
                [renderEncoder setVertexBuffer:temperatureBuffer
                                        offset:0 atIndex:EBRenderBufferIndexTemperatures];
            }

            [renderEncoder setVertexBuffer:_colors
                                    offset:0 atIndex:EBRenderBufferIndexColors];

            [renderEncoder setVertexBuffer:_dynamicUniformBuffers[_currentBufferIndex]
                                    offset:0 atIndex:EBRenderBufferIndexUniforms];

            [renderEncoder setFragmentTexture:_texture atIndex:EBTextureIndexColorMap];

            [renderEncoder drawPrimitives:MTLPrimitiveTypePoint
                              vertexStart:0
                              vertexCount:3
                            instanceCount:1];
        }

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer popDebugGroup];
}

- (void)setRenderScale:(float)renderScale withDrawableSize:(CGSize)size { 
    _renderScale = renderScale;

    [self updateProjection:size];
}

- (void) loadMetal:(nonnull MTKView *)mtkView
{
    NSError *error = nil;

    // Load all the shader files with a .metal file extension in the project
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    // Load the vertex function from the library
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

    // Load the fragment function from the library
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    mtkView.sampleCount = 1;

    {
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.label = @"RenderPipeline";
        pipelineDescriptor.sampleCount = mtkView.sampleCount;
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        pipelineDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor  = MTLBlendFactorSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOne;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOne;

        _renderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        if (!_renderPipeline)
        {
            NSLog(@"Failed to create render pipeline state, error %@", error);
        }
    }

    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    // Create and allocate the dynamic uniform buffer objects.
    for(NSUInteger i = 0; i < MaxRenderBuffersInFlight; i++)
    {
        // Indicate shared storage so that both the  CPU can access the buffers
        const MTLResourceOptions storageMode = MTLResourceStorageModeShared;

        _dynamicUniformBuffers[i] = [_device newBufferWithLength:sizeof(EBUniforms)
                                                  options:storageMode];

        _dynamicUniformBuffers[i].label = [NSString stringWithFormat:@"UniformBuffer%lu", i];
    }

}

@end
