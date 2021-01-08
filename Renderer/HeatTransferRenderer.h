//
//  HeatTransferRenderer.h
//  HeatTransfer
//
//  Created by Eloi on 1/7/21.
//

@import MetalKit;

@interface HeatTransferRenderer : NSObject
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

- (void)drawableSizeWillChange:(CGSize)size;

- (void)drawWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
              tempBuffer:(nonnull id<MTLBuffer>)tempBuffer
                 numXElements:(NSUInteger)numXElements
                 numYElements:(NSUInteger)numYElements
                 numZElements:(NSUInteger)numZElements
                       inView:(nonnull MTKView *)view;


- (void)setRenderScale:(float)renderScale withDrawableSize:(CGSize)size;

@property (nonatomic, readonly, nonnull) id<MTLDevice> device;


@end
