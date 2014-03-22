//
//  BBLineGraph.m
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBLineGraph.h"
#import "UIBezierPath+Smoothing.h"

@interface BBGraph ()

@property(nonatomic, strong) NSMutableDictionary *seriesLayers; //an array of calayers;
@property(nonatomic, strong) NSMutableDictionary *axisDataPointLayers; //an array of calayers;
@property(nonatomic, strong) NSMutableDictionary *axisLayers; //an array of calayers;
@property(nonatomic, strong) NSMutableDictionary *numberOfAxisLabels; //A number of labels per axis where the key is a BBLineGraphAxis enum
@property(nonatomic, strong) NSMutableDictionary *intervalOfAxisLabels; //The interval to display axis labels

@property(nonatomic, strong) NSMutableArray *labels;
@property(nonatomic, strong) NSMutableArray *axisLabelStrings; //Array of dictionaries containing the strings for each axis [BBLineGraphAxis][@(value)]

@property(nonatomic, strong) NSArray *series; // an array of arrays of nsvalues for cgpoints

@property(nonatomic, assign) CGRect valueSpace;
@property(nonatomic, assign) CGRect screenSpace;

@property(nonatomic, assign) CGFloat highestYValue;
@property(nonatomic, assign) CGFloat highestXValue;

@property(nonatomic, assign) CGFloat lowestYValue;
@property(nonatomic, assign) CGFloat lowestXValue;

@property(nonatomic, assign) CGPoint graphSpaceInset;

@property(nonatomic, strong) UIView *screenSpaceView;
@property(nonatomic, strong) UIView *axisView;

- (void)setUpValueSpace;

- (void)setupGraphSpace;

- (void)populateSeries;

- (CGColorRef)colorForSeries:(NSInteger)series;

@end

@interface BBLineGraph ()

@end

@implementation BBLineGraph



@end
