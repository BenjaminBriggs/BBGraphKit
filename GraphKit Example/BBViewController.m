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
    
    self.lineGraph.scaleYAxisToValues = NO;
    self.lineGraph.scaleXAxisToValues = NO;
    
    self.lineGraph.axisColor = [UIColor blueColor];
    
    self.lineGraph.axisDataPointWidth = 1.f;
    
    self.lineGraph.xPadding = 5;
    self.lineGraph.yPadding = 5;
}

- (void)viewDidAppear:(BOOL)animated
{
//    [self.lineGraph animateGraph];
}
#pragma mark - BBLineGraphDataSource

- (NSInteger)graph:(BBGraph *)graph numberOfPointsInSeries:(NSInteger)line
{
	return 10;
}

- (CGPoint)graph:(BBGraph *)graph valueForPointAtIndex:(NSIndexPath *)indexPath
{
	return CGPointMake(arc4random_uniform(99), arc4random_uniform(99));
}

- (NSInteger)numberOfSeriesInGraph:(BBGraph *)lineGraph
{
    return 3;
}

//- (CGFloat)graph:(BBGraph *)graph intervalOfLabelsForAxis:(BBGraphAxis)axis
//{
//    if (axis == BBGraphAxisY)
//    {
//        return 100;
//    }
//    return 1;
//}
- (NSUInteger)graph:(BBGraph *)graph numberOfLabelsForAxis:(BBGraphAxis)axis
{
    return 7;
}
#pragma mark - BBLineGraphDelegate

- (UIColor *)graph:(BBGraph *)graph colorForSeries:(NSInteger)series
{
    return [UIColor colorWithHue:arc4random_uniform(100)/100.0 saturation:1 brightness:1 alpha:1];
}

- (CGFloat)lineGraph:(BBLineGraph *)lineGraph widthForLine:(NSUInteger)line
{
    return 1.0;
}

- (NSString *)graph:(BBGraph *)graph stringForLabelAtValue:(CGFloat)value onAxis:(BBGraphAxis)axis
{
    return [NSString stringWithFormat:@"%.1f", value];
}
- (NSTimeInterval)lineGraph:(BBLineGraph *)lineGraph animationDurationForLine:(NSUInteger)line
{
    return 2;
}
@end
