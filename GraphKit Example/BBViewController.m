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
    
    self.lineGraph.axisColor = [UIColor blueColor];

	self.items = @[[NSValue valueWithCGPoint:CGPointMake(-1, 1000)],
                   [NSValue valueWithCGPoint:CGPointMake(0, 0)],
				   [NSValue valueWithCGPoint:CGPointMake(1, -1000)],
				   [NSValue valueWithCGPoint:CGPointMake(2, 800)],
				   [NSValue valueWithCGPoint:CGPointMake(3, 700)],
				   [NSValue valueWithCGPoint:CGPointMake(4, 600)],
				   [NSValue valueWithCGPoint:CGPointMake(5, 500)],
				   [NSValue valueWithCGPoint:CGPointMake(6, 600)],
				   [NSValue valueWithCGPoint:CGPointMake(7, 0)],
				   [NSValue valueWithCGPoint:CGPointMake(8, -1200)],
				   [NSValue valueWithCGPoint:CGPointMake(9, 900)],
                   [NSValue valueWithCGPoint:CGPointMake(10, 1000)]];
}

#pragma mark - BBLineGraphDataSource

- (NSInteger)graph:(BBGraph *)graph numberOfPointsInSeries:(NSInteger)line
{
	return self.items.count;
}

- (CGPoint)graph:(BBGraph *)graph valueForPointAtIndex:(NSIndexPath *)indexPath
{
	return [self.items[indexPath.point] CGPointValue];
}

- (CGFloat)graph:(BBGraph *)graph intervalOfLabelsForAxis:(BBGraphAxis)axis
{
    if (axis == BBGraphAxisY)
    {
        return 100;
    }
    return 1;
}

#pragma mark - BBLineGraphDelegate

- (UIColor *)graph:(BBGraph *)graph colorForSeries:(NSInteger)series
{
    return [UIColor greenColor];
}

- (CGFloat)lineGraph:(BBLineGraph *)lineGraph widthForLine:(NSUInteger)line
{
    return 1.0;
}
@end
