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
    
    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (void)drawableResize:(CGSize)size {
    <#code#>
}

- (void)renderToMetalLayer:(nonnull CAMetalLayer *)metalLayer {
    <#code#>
}

- (BOOL)commitEditingAndReturnError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    <#code#>
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    <#code#>
}

@end
