//
//  BBBarGraph.h
//  GraphKit
//
//  Created by Benjamin Briggs on 19/03/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraph.h"

@class BBBarGraph;

@protocol BBBarGraphDelegate <BBGraphDelegate>

@optional
- (CGFloat)barGraph:(BBBarGraph *)barGraph widthForSeries:(NSUInteger)series;

//The number of length of time (seconds) it takes to draw each line.  If you implement this method you must call -animateGraph;
- (NSTimeInterval)barGraph:(BBBarGraph *)barGraph animationDurationForSeries:(NSUInteger)series;
@end

@interface BBBarGraph : BBGraph

@property (nonatomic, weak) IBOutlet id<BBBarGraphDelegate> delegate;

@end
