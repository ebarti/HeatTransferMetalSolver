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
    }
    return self;
}

- (nonnull MPSGraphTensor *)boundaryConditionTensor:(EBMatrixDirection)direction {
    
    MPSShape* pshape = @[[NSNumber numberWithUnsignedInt:_config->numXElements],
                         [NSNumber numberWithUnsignedInt:_config->numXElements],
                         [NSNumber numberWithUnsignedInt:_config->numXElements]];
    MPSGraphTensor *tensor = [self variableWithData:pdata shape:pshape dataType:MPSDataTypeFloat32 name:@"Some weird name"];
    
    return tensor;
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
