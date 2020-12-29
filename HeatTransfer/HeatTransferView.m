//
//  HeatTransferView.m
//  HeatTransfer
//
//  Created by Eloi on 12/28/20.
//

#import "HeatTransferView.h"

@implementation HeatTransferView

// Init
- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self initCommon];
    }
    return self;
}


- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initCommon];
    }
    return self;
}


- (void)initCommon
{
    _metalLayer = (CAMetalLayer*) self.layer;
    self.layer.delegate = self;
}


// Rendering
- (void)stopRenderLoop
{
    // Noop. Needed to implement as this is a sublass...
}


- (void)dealloc
{
    [self stopRenderLoop];
}


- (void)render
{
    [_delegate renderToMetalLayer:_metalLayer];
}

@end
