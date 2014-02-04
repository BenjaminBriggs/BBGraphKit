//
//  BBLineGraph.h
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraph.h"

@class BBLineGraph;

@protocol BBLineGraphDelegate <BBGraphDelegate>

@optional
- (CGFloat)lineGraph:(BBLineGraph *)lineGraph widthForLine:(NSUInteger)line;

//The number of length of time (seconds) it takes to draw each line.  If you implement this method you must call -animateGraph;
- (NSTimeInterval)lineGraph:(BBLineGraph *)lineGraph animationDurationForLine:(NSUInteger)line;

//Whether or not the line is curved
- (BOOL)lineGraph:(BBLineGraph *)lineGraph curveLine:(NSUInteger)line;
@end

@interface BBLineGraph : BBGraph

@property (nonatomic, weak) IBOutlet id<BBLineGraphDelegate> delegate;

//Set the lowest value on the axis based on the lowest data point (Default is YES)
@property (nonatomic, assign) BOOL scaleXAxisToValues;
@property (nonatomic, assign) BOOL scaleYAxisToValues;

//Show lines at x=0 and y=0 (Default is YES)
@property (nonatomic, assign) BOOL displayXAxis;
@property (nonatomic, assign) BOOL displayYAxis;
//Round up & down the highest and lowest points on an axis to a pretty number (Default is YES)
@property (nonatomic, assign) BOOL roundXAxis;
@property (nonatomic, assign) BOOL roundYAxis;
//It may be useful to not display a zero label on the axis (eg. a graph with bisecting axes)
@property (nonatomic, assign) BOOL displayZeroAxisLabel;

- (void)reloadData;

- (void)animateGraph;

- (NSInteger)numberOfLines;
- (NSInteger)numberOfPointsInLine:(NSInteger)line;

@end


@interface NSIndexPath (BBLineGraph)

+ (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@property(nonatomic,readonly) NSInteger line;
@property(nonatomic,readonly) NSInteger point;

@end