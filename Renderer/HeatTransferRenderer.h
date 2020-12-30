//
//  HeatTransferRenderer.h
//  HeatTransfer
//
//  Created by Eloi on 12/30/20.
//

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface HeatTransferRenderer : NSObject

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device;

- (void)renderToMetalLayer:(nonnull CAMetalLayer*)metalLayer;

- (void)drawableResize:(CGSize)drawableSize;
@end

