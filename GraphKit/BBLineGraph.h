//
//  BBLineGraph.h
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraph.h"

@interface BBLineGraph : BBGraph

//Set the lowest value on the axis based on the lowest data point (Default is YES)
@property (nonatomic, assign) BOOL scaleXAxisToValues;
@property (nonatomic, assign) BOOL scaleYAxisToValues;

//Show lines at x=0 and y=0
@property (nonatomic, assign) BOOL displayXAxis;
@property (nonatomic, assign) BOOL displayYAxis;

- (void)reloadData;

- (NSInteger)numberOfLines;
- (NSInteger)numberOfPointsInLine:(NSInteger)line;

@end

@interface NSIndexPath (BBLineGraph)

+ (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@property(nonatomic,readonly) NSInteger line;
@property(nonatomic,readonly) NSInteger point;

@end