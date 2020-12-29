//
//  HeatTransferView.h
//  HeatTransfer
//
//  Created by Eloi on 12/28/20.
//

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>

@import AppKit;

//************************************************************************
// Protocol to provide resize and redraw callbacks to a delegate
//************************************************************************
@protocol HeatTransferViewDelegate <NSObject>

// Methods
- (void)drawableResize:(CGSize)size;
- (void)renderToMetalLayer:(nonnull CAMetalLayer *)metalLayer;

@end


//************************************************************************
// Interface for the Heat Transfer NSView
//************************************************************************
@interface HeatTransferView : NSView <CALayerDelegate>

// Properties
@property (nonatomic, nonnull, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic, nullable) id<HeatTransferViewDelegate> delegate;

// Methods
- (void)initCommon;
- (void)stopRenderLoop;
- (void)render;

@end
