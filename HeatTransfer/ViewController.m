//
//  ViewController.m
//  HeatTransfer
//
//  Created by Eloi on 12/29/20.
//

#import "ViewController.h"
#import "HeatTransferView.h"
#import "HeatTransferRenderer.h"

#import <QuartzCore/CAMetalLayer.h>


@implementation ViewController {
    HeatTransferRenderer* _renderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Create device
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

    // Set the view
    HeatTransferView *view = (HeatTransferView *)self.view;

    view.metalLayer.device = device;

    // This is the key piece here....
    view.delegate = self;

    _renderer = [[HeatTransferRenderer alloc] initWithMetalDevice:device];
}


- (void)drawableResize:(CGSize)size {
    [_renderer drawableResize:size];
}

- (void)renderToMetalLayer:(nonnull CAMetalLayer *)metalLayer {
    [_renderer renderToMetalLayer:metalLayer];
}


@end
