//
//  QnSolverGraph.h
//  HeatTransfer
//
//  Created by Eloi on 1/3/21.
//

#import <MetalPerformanceShadersGraph/MetalPerformanceShadersGraph.h>
#import "HeatTransferSimulation.h"

typedef enum EBMatrixDirection {
    north = 1,
    south = 2,
    east = 3,
    west = 4,
    top = 5,
    bottom = 6
} EBMatrixDirection;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(11.0))
@interface EBGraph : MPSGraph{
    const EBSimulationConfig* _config;
}
-(instancetype) initWithConfig:(EBSimulationConfig *)config;
-(MPSGraphTensor *) boundaryConditionTensor:(EBMatrixDirection) direction;
@end

API_AVAILABLE(macos(11.0))
@interface QnSolverGraph : EBGraph
-(instancetype) initWithConfig:(EBSimulationConfig *)config;
-(MPSGraphTensor *) qnSolver:(MPSGraphTensor*) tn;
@end

API_AVAILABLE(macos(11.0))
@interface Tn1SolverGraph : EBGraph
-(instancetype) initWithConfig:(EBSimulationConfig *)config;
-(MPSGraphTensor *) tn1Solver:(MPSGraphTensor*) tn
                              tsup:(MPSGraphTensor*) tsup;
@end

NS_ASSUME_NONNULL_END
