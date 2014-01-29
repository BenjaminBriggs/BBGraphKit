//
//  BBGraph.h
//  GraphKit
//
//  Created by Stephen Groom on 29/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BBGraph;

typedef NS_ENUM(NSInteger, BBGraphStyle) {
    BBGraphStylePlain = 0,	// regular line graph
    BBGraphStyleStacked		// Not yet implemented
};

typedef NS_ENUM(NSInteger, BBGraphAxis) {
    BBGraphAxisX = 0,
    BBGraphAxisY
};

@protocol BBGraphDataSource <NSObject>

- (NSInteger)graph:(BBGraph *)lineGraph numberOfPointsInSeries:(NSInteger)line;

- (CGPoint)graph:(BBGraph *)lineGraph valueForPointAtIndex:(NSIndexPath *)indexPath; // Use + (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@optional

- (NSInteger)numberOfSeriesInGraph:(BBGraph *)lineGraph; // Default is 1 if not implemented

//There are two ways we can add data points to an axis.  Either by specifying a number of points to add or the increment value
//If both are implemented then we will use intervalOfLabelsForAxis
- (NSUInteger)graph:(BBGraph *)graph intervalOfLabelsForAxis:(BBGraphAxis)axis;
- (NSUInteger)graph:(BBGraph *)graph numberOfLabelsForAxis:(BBGraphAxis)axis;

@end

@protocol BBGraphDelegate <NSObject>

@optional

- (UIColor *)graph:(BBGraph *)graph colorForSeries:(NSInteger)series;
- (NSString *)graph:(BBGraph *)graph stringForLabelAtValue:(NSInteger)value onAxis:(BBGraphAxis)axis;

@end

@interface BBGraph : UIView

@property (nonatomic, weak) IBOutlet id<BBGraphDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id<BBGraphDelegate> delegate;

@property (nonatomic, assign) BBGraphAxis orderedAxis; // by defualt X;

@property (nonatomic, strong) UIColor *axisColor;
@end
