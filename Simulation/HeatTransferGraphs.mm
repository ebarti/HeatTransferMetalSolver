//
//  QnSolverGraph.m
//  HeatTransfer
//
//  Created by Eloi on 1/3/21.
//

#import "HeatTransferGraphs.h"
/*
 Create an MPSNDArray:
    - Create Descriptor
    - Create NDArray
 */



@implementation EBGraph
- (nonnull instancetype)initWithConfig:(nonnull EBSimulationConfig *)config { 
    <#code#> self = [super init];
    if (self) {
        _config = config;
        _pShape = @[[NSNumber numberWithUnsignedInt:_config->numXElements],
                             [NSNumber numberWithUnsignedInt:_config->numYElements],
                             [NSNumber numberWithUnsignedInt:_config->numZElements]];
        _pDescriptor = [MPSNDArrayDescriptor descriptorWithDataType:MPSDataTypeFloat32 shape:_pShape];
        uint32_t size = _config->numXElements*_config->numYElements*_config->numYElements;
        float data[6][size];
        // Flat[x + SIZE_X * (y + SIZE_Y * z)] = Original[x, y, z]
        for (int dir = 1; dir <= 6; dir++) {
            EBMatrixDirection dirEnum = (EBMatrixDirection)dir;
            for (int xx=0; xx<_config->numXElements; xx++) {
                for (int yy=0; yy<_config->numXElements; yy++) {
                    for (int zz=0; zz<_config->numXElements; zz++) {
                        switch (dirEnum) {
                            case south:
                                if (xx == 0) {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =0.f;
                                } else {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =1.f;
                                }
                                break;
                            case north:
                                if (xx == _config->numXElements-1) {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =0.f;
                                } else {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =1.f;
                                }
                                break;
                            case east:
                                if (yy == 0) {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =0.f;
                                } else {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =1.f;
                                }
                                break;
                            case west:
                                if (yy == _config->numYElements-1) {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =0.f;
                                } else {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =1.f;
                                }
                                break;
                            case top:
                                if (zz == 0) {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =0.f;
                                } else {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =1.f;
                                }
                                break;
                            case bottom:
                                if (zz == _config->numZElements-1) {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =0.f;
                                } else {
                                    data[dir][xx + _config->numXElements*(yy + _config->numYElements*zz)] =1.f;
                                }
                                break;
                            default:
                                break;
                        }
                    }
                }
            }
        }
        
        for(int dir=1; dir<=6;dir++) {
            NSData * boundaryData = [NSData dataWithBytes:data[dir] length:size*sizeof(float)];
            _pBoundaries[dir] = [self variableWithData:boundaryData shape:_pShape dataType:MPSDataTypeFloat32 name:nil];
        }
    }
    return self;
}

@end


@implementation QnSolverGraph

- (nonnull instancetype)initWithConfig:(nonnull EBSimulationConfig *)config { 
    return [super initWithConfig:config];
}
- (nonnull MPSGraphTensor *)qnSolver:(nonnull MPSGraphTensor *)tn {
    
    return nil;
}
@end



@implementation Tn1SolverGraph

- (nonnull MPSGraphTensor *)tn1Solver:(nonnull MPSGraphTensor *)tn tsup:(nonnull MPSGraphTensor *)tsup { 
    return nil;
}

- (nonnull instancetype)initWithConfig:(nonnull EBSimulationConfig *)config { 
    return [super initWithConfig:config];
}


@end
