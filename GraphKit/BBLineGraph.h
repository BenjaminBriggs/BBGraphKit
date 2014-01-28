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

@interface BBLineGraph : UIView

@property (nonatomic, weak) IBOutlet id<BBLineGraphDataSource> dataSource;
@property (nonatomic, assign) BBLineGraphAxis orderedAxis; // by defualt X;

- (void)reloadData;

- (NSInteger)numberOfLines;
- (NSInteger)numberOfPointsInLine:(NSInteger)line;

@end

@interface NSIndexPath (BBLineGraph)

+ (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line;

@property(nonatomic,readonly) NSInteger line;
@property(nonatomic,readonly) NSInteger point;

@end