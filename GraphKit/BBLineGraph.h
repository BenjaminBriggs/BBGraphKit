//
//  BBLineGraph.h
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BBLineGraphStyle) {
    BBLineGraphStylePlain = 0,	// regular line graph
    BBLineGraphStyleStacked		// Not yet implemented
};

typedef NS_ENUM(NSInteger, BBLineGraphAxis) {
    BBLineGraphAxisX = 0,
    BBLineGraphAxisY
};

@class BBLineGraph;

@protocol BBLineGraphDataSource <NSObject>

- (NSInteger)lineGraph:(BBLineGraph *)lineGraph numberOfPointsInLine:(NSInteger)line;

- (CGPoint)lineGraph:(BBLineGraph *)lineGraph valueForPointAtIndex:(NSIndexPath *)indexPath; // Use + (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@optional

- (NSInteger)numberOfLinesInLineGraph:(BBLineGraph *)lineGraph; // Default is 1 if not implemented

@end

@protocol BBLineGraphDelegate <NSObject>

@optional

- (UIColor *)lineGraph:(BBLineGraph *)lineGraph colorForLine:(NSInteger)line;

@end

@interface BBLineGraph : UIView

@property (nonatomic, weak) IBOutlet id<BBLineGraphDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id<BBLineGraphDelegate> delegate;
@property (nonatomic, assign) BBLineGraphAxis orderedAxis; // by defualt X;

//Set the lowest value on the axis based on the lowest data point (Default is NO)
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