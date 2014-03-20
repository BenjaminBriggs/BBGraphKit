//
//  BBGraph.h
//  GraphKit
//
//  Created by Stephen Groom on 29/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BBGraph;

extern NSString *const xAxisLayerKey;
extern NSString *const yAxisLayerKey;

extern CGFloat const axisDataPointSize;
extern CGFloat const axisDataPointPadding;

typedef NS_ENUM(NSInteger, BBGraphAxis) {
    BBGraphAxisX = 0,
    BBGraphAxisY
};

@protocol BBGraphDataSource <NSObject>

- (NSUInteger)graph:(BBGraph *)lineGraph numberOfPointsInSeries:(NSInteger)series;

- (CGPoint)graph:(BBGraph *)lineGraph valueForPointAtIndex:(NSIndexPath *)indexPath; // Use + (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@optional

- (NSUInteger)numberOfSeriesInGraph:(BBGraph *)lineGraph; // Default is 1 if not implemented

//There are two ways we can add data points to an axis.  Either by specifying a number of points to add or the increment value
//If both are implemented then we will use intervalOfLabelsForAxis
- (CGFloat)graph:(BBGraph *)graph intervalOfLabelsForAxis:(BBGraphAxis)axis;
- (NSUInteger)graph:(BBGraph *)graph numberOfLabelsForAxis:(BBGraphAxis)axis;

@end

@protocol BBGraphDelegate <NSObject>

@optional

- (UIColor *)graph:(BBGraph *)graph colorForSeries:(NSInteger)series;
- (NSString *)graph:(BBGraph *)graph stringForLabelAtValue:(CGFloat)value onAxis:(BBGraphAxis)axis;

@end

@interface BBGraph : UIView

@property (nonatomic, weak) IBOutlet id<BBGraphDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id<BBGraphDelegate> delegate;

@property (nonatomic, assign) BBGraphAxis orderedAxis; // by defualt X;

@property (nonatomic, assign) CGFloat axisWidth;
@property (nonatomic, assign) CGFloat axisDataPointWidth;

@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, strong) UIColor *axisLabelColor;
@property (nonatomic, strong) UIColor *graphBackgroundColor;

@property (nonatomic, strong) UIFont *xAxisFont;
@property (nonatomic, strong) UIFont *yAxisFont;

//Set the lowest value on the axis based on the lowest data point (Default is YES)
@property (nonatomic, assign) BOOL scaleXAxisToValues;
@property (nonatomic, assign) BOOL scaleYAxisToValues;

//Padding between the outer bounds of the view and the outer edge of the axis (default = 10)
@property (nonatomic, assign) CGFloat xPadding;
@property (nonatomic, assign) CGFloat yPadding;

//Show lines at x=0 and y=0 (Default is YES)
@property (nonatomic, assign) BOOL displayXAxis;
@property (nonatomic, assign) BOOL displayYAxis;
//Round up & down the highest and lowest points on an axis to a pretty number (Default is YES)
@property (nonatomic, assign) BOOL roundXAxis;
@property (nonatomic, assign) BOOL roundYAxis;
//It may be useful to not display a zero label on the axis (eg. a graph with bisecting axes)
@property (nonatomic, assign) BOOL displayZeroAxisLabel;

- (void)reloadData;

//- (void)animateGraph;

- (NSInteger)numberOfSeries;

- (NSInteger)numberOfPointsInLine:(NSUInteger)line;

- (CGPoint)convertPointToScreenSpace:(CGPoint)point;
- (CGPoint)convertPointToValueSpace:(CGPoint)point;

@end

@interface NSIndexPath (BBLineGraph)

+ (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@property(nonatomic,readonly) NSInteger line;
@property(nonatomic,readonly) NSInteger point;

@end
