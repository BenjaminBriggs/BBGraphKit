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
<BBLineGraphDataSource>

@property (nonatomic, strong) NSArray *items;
@end

@implementation BBViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.items = @[[NSValue valueWithCGPoint:CGPointMake(0, 1)],
				   [NSValue valueWithCGPoint:CGPointMake(1, 0)],
				   [NSValue valueWithCGPoint:CGPointMake(2, 2)],
				   [NSValue valueWithCGPoint:CGPointMake(3, 0)],
				   [NSValue valueWithCGPoint:CGPointMake(4, 3)],
				   [NSValue valueWithCGPoint:CGPointMake(5, 0)],
				   [NSValue valueWithCGPoint:CGPointMake(6, 4)],
				   [NSValue valueWithCGPoint:CGPointMake(7, 0)],
				   [NSValue valueWithCGPoint:CGPointMake(8, 5)],
				   [NSValue valueWithCGPoint:CGPointMake(9, 0)]];
}

- (NSInteger)lineGraph:(BBLineGraph *)lineGraph numberOfPointsInLine:(NSInteger)line
{
	return self.items.count;
}

- (CGPoint)lineGraph:(BBLineGraph *)lineGraph valueForPointAtIndex:(NSIndexPath *)indexPath
{
	return [self.items[indexPath.point] CGPointValue];
}

@end
