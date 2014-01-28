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
<BBLineGraphDataSource,
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

- (NSInteger)lineGraph:(BBLineGraph *)lineGraph numberOfPointsInLine:(NSInteger)line
{
	return self.items.count;
}

- (CGPoint)lineGraph:(BBLineGraph *)lineGraph valueForPointAtIndex:(NSIndexPath *)indexPath
{
	return [self.items[indexPath.point] CGPointValue];
}

#pragma mark - BBLineGraphDelegate

- (UIColor *)lineGraph:(BBLineGraph *)lineGraph colorForLine:(NSInteger)line
{
    return [UIColor greenColor];
}

@end
