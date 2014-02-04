//
//  BBViewController.m
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBViewController.h"
#import "BBLineGraph.h"

@interface BBViewController ()
<BBGraphDataSource,
BBLineGraphDelegate>

@property (weak, nonatomic) IBOutlet BBLineGraph *lineGraph;
@property (nonatomic, strong) NSArray *items;
@end

@implementation BBViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

    //TODO: Think about what is going to be a property and what is going to be a delegate method
    self.lineGraph.displayXAxis = YES;
    self.lineGraph.displayYAxis = YES;
    
    self.lineGraph.scaleYAxisToValues = YES;
    self.lineGraph.scaleXAxisToValues = YES;
    
    self.lineGraph.axisColor = [UIColor lightGrayColor];
    
    self.lineGraph.axisDataPointWidth = 1.f;
    
    self.lineGraph.xPadding = 5;
    self.lineGraph.yPadding = 5;
}

- (void)viewDidAppear:(BOOL)animated
{
//    [self.lineGraph animateGraph];
}
#pragma mark - BBGraphDataSource

- (NSInteger)graph:(BBGraph *)graph numberOfPointsInSeries:(NSInteger)line
{
	return 21;
}

- (CGPoint)graph:(BBGraph *)graph valueForPointAtIndex:(NSIndexPath *)indexPath
{
	return CGPointMake(indexPath.point*100, (double)arc4random_uniform(750)-200);
}

- (NSInteger)numberOfSeriesInGraph:(BBGraph *)lineGraph
{
    return 5;
}

- (CGFloat)graph:(BBGraph *)graph intervalOfLabelsForAxis:(BBGraphAxis)axis
{
    if (axis == BBGraphAxisY)
    {
        return 100;
    }
    return 200;
}

//- (NSUInteger)graph:(BBGraph *)graph numberOfLabelsForAxis:(BBGraphAxis)axis
//{
//    return 4;
//}

#pragma mark - BBGraphDelegate

- (UIColor *)graph:(BBGraph *)graph colorForSeries:(NSInteger)series
{
    switch (series) {
        case 0:
            return [UIColor colorWithHue:0.011 saturation:0.623 brightness:0.894 alpha:1.000];
            break;
            
        case 1:
            return [UIColor colorWithHue:0.583 saturation:0.673 brightness:0.600 alpha:1.000];
            break;
            
        case 2:
            return [UIColor colorWithHue:0.312 saturation:0.261 brightness:0.827 alpha:1.000];
            break;
            
        default:
            return [UIColor colorWithHue:arc4random_uniform(100)/100.0 saturation:1 brightness:1 alpha:1];
            break;
    }
}


- (NSString *)graph:(BBGraph *)graph stringForLabelAtValue:(CGFloat)value onAxis:(BBGraphAxis)axis
{
    return [NSString stringWithFormat:@"%.1f", value];
}

#pragma mark - BBLineGraphDelegate

- (CGFloat)lineGraph:(BBLineGraph *)lineGraph widthForLine:(NSUInteger)line
{
    return 1.0;
}

- (NSTimeInterval)lineGraph:(BBLineGraph *)lineGraph animationDurationForLine:(NSUInteger)line
{
    return 2;
}

- (BOOL)lineGraph:(BBLineGraph *)lineGraph curveLine:(NSUInteger)line
{
    return YES;
}
@end
