//
//  BBGraph.m
//  GraphKit
//
//  Created by Benjamin Briggs on 29/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraph.h"
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

CGFloat const axisDataPointSize = 5.f;
CGFloat const axisDataPointPadding = 1.f;

NSString *const xAxisLayerKey = @"xAxisLayer";
NSString *const yAxisLayerKey = @"yAxisLayer";

@implementation BBGraph

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.seriesLayers = [NSMutableDictionary dictionary];
    self.axisDataPointLayers = [NSMutableDictionary dictionary];
    self.axisLayers = [NSMutableDictionary dictionary];
    self.numberOfAxisLabels = [NSMutableDictionary dictionary];
    self.intervalOfAxisLabels = [NSMutableDictionary dictionary];
    self.labels = [NSMutableArray array];

    //Defaults
    self.axisDataPointWidth = 1.0f;
    self.axisWidth = 1.0f;
    self.scaleYAxisToValues = YES;
    self.scaleXAxisToValues = YES;
    self.displayXAxis = YES;
    self.displayYAxis = YES;
    self.roundXAxis = YES;
    self.roundYAxis = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.xAxisFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        self.yAxisFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    }
    else {
        self.xAxisFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.yAxisFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    self.xPadding = 10.f;
    self.yPadding = 10.f;


    self.axisColor = [UIColor blackColor];
}


- (NSInteger)numberOfSeries {
    return self.series.count;
}

- (NSInteger)numberOfPointsInSeries:(NSUInteger)series {
    if (series <= 0 && series > self.series.count) {
        NSArray *points = self.series[series];
        return points.count;
    }
    else {
        return 0;
    }
}

#pragma mark - Create Data Structure

- (void)populateSeries {
    // get the number of lines in the graph
    NSUInteger numberOfSeries = 1;

    // check if the data source provided a number of lines
    if ([self.dataSource respondsToSelector:@selector(numberOfSeriesInGraph:)]) {
        numberOfSeries = [self.dataSource numberOfSeriesInGraph:self];
    }

    // set up some holders fpr the high and low values
    CGFloat highestYValue = -MAXFLOAT;
    CGFloat highestXValue = -MAXFLOAT;

    CGFloat lowestYValue = MAXFLOAT;
    CGFloat lowestXValue = MAXFLOAT;

    // create an array to holder the lines
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:numberOfSeries];

    // loop to get the lines
    for (NSInteger l = 0; l < numberOfSeries; l++) {

        // check how many points are in this series
        NSUInteger numberOfPoints = [self.dataSource graph:self
                                    numberOfPointsInSeries:l];

        // create an array to hold the points
        NSMutableArray *points = [NSMutableArray arrayWithCapacity:numberOfPoints];

        // loop to get the points for this series
        for (NSInteger p = 0; p < numberOfPoints; p++) {

            // get the point from the data source
            CGPoint point = [self.dataSource graph:self
                              valueForPointAtIndex:[NSIndexPath indexPathForPoint:p
                                                                         inSeries:l]];

            // added it to the points array
            [points addObject:[NSValue valueWithCGPoint:point]];

            // get the highest and lowest values in the data set;
            highestYValue = MAX(highestYValue, point.y);
            highestXValue = MAX(highestXValue, point.x);

            lowestYValue = MIN(lowestYValue, point.y);
            lowestXValue = MIN(lowestXValue, point.x);

        }

        // sort the series
        [points sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if (self.orderedAxis == BBGraphAxisX) {
                if ([obj1 CGPointValue].x > [obj2 CGPointValue].x) {
                    return (NSComparisonResult) NSOrderedDescending;
                }

                if ([obj1 CGPointValue].x < [obj2 CGPointValue].x) {
                    return (NSComparisonResult) NSOrderedAscending;
                }
                return (NSComparisonResult) NSOrderedSame;
            }
            else {
                if ([obj1 CGPointValue].y > [obj2 CGPointValue].y) {
                    return (NSComparisonResult) NSOrderedDescending;
                }

                if ([obj1 CGPointValue].y < [obj2 CGPointValue].y) {
                    return (NSComparisonResult) NSOrderedAscending;
                }
                return (NSComparisonResult) NSOrderedSame;

            }
        }];

        // add the array of points to the lines array, still with me?
        [lines addObject:points];
    }

    // save the lines array
    self.series = lines;

    // finaly round and save the high and low values
    if (self.roundYAxis) {
        self.highestYValue = [self roundValue:highestYValue Up:YES];
        self.highestXValue = [self roundValue:highestXValue Up:YES];
    }
    else {
        self.highestXValue = highestXValue;
        self.highestYValue = highestYValue;
    }

    if (self.roundXAxis) {
        self.lowestYValue = [self roundValue:lowestYValue Up:NO];
        self.lowestXValue = [self roundValue:lowestXValue Up:NO];
    }
    else {
        self.lowestXValue = lowestXValue;
        self.lowestYValue = lowestYValue;
    }

    [self calclateInset];
}

- (void)populateAxisLabelStrings {

}

- (void)calclateInset {
    self.axisLabelStrings = [NSMutableArray array];

    CGPoint inset = CGPointZero;

    for (int i = 0; i < 2; i++) //Iterate over the axis type enum which we know contains to types
    {
        BBGraphAxis axis = (BBGraphAxis) i;
        CGFloat maxLabelWidth = 0.f;
        CGFloat maxLabelHeight = 0.f;

        //Get the number & interval of axis labels
        double numberOfLabels = 0;
        CGFloat intervalOfLabels = 0.f;

        //Get the information from the data source required to calculate & draw these
        if ([self.dataSource respondsToSelector:@selector(graph:intervalOfLabelsForAxis:)]) {
            intervalOfLabels = [self.dataSource graph:self intervalOfLabelsForAxis:axis];
            if (axis == BBGraphAxisX) {
                numberOfLabels = floor((self.highestXValue - self.lowestXValue) / intervalOfLabels);
            }
            else if (axis == BBGraphAxisY) {
                numberOfLabels = floor((self.highestYValue - self.lowestYValue) / intervalOfLabels);

            }
        }
        else if ([self.dataSource respondsToSelector:@selector(graph:numberOfLabelsForAxis:)]) {
            numberOfLabels = [self.dataSource graph:self numberOfLabelsForAxis:axis];
            if (axis == BBGraphAxisX) {
                intervalOfLabels = (self.highestXValue - self.lowestXValue) / numberOfLabels;
            }
            else if (axis == BBGraphAxisY) {
                intervalOfLabels = (self.highestYValue - self.lowestYValue) / numberOfLabels;

            }
        }

        //Iterate through the labels and find their associated strings
        for (int j = 0; j <= numberOfLabels; j++) {
            NSString *labelText;
            //Calculate the value of the label we need
            CGFloat labelValue;
            if (axis == BBGraphAxisX)
                labelValue = self.lowestXValue + j * intervalOfLabels;
            else
                labelValue = self.lowestYValue + j * intervalOfLabels;

            labelValue -= fmodf(labelValue, intervalOfLabels);

            // ask the delegate for a formated string
            if ([self.delegate respondsToSelector:@selector(graph:stringForLabelAtValue:onAxis:)]) {
                labelText = [self.delegate graph:self stringForLabelAtValue:labelValue onAxis:axis];
            }
                    // or use basic formatting
            else {
                labelText = [NSString stringWithFormat:@"%g", labelValue];
            }

            //Save the label to a property to prevent calling the above delegate method more than once per label per reload
            if (j == 0) {
                [self.axisLabelStrings addObject:[NSMutableDictionary dictionary]];
            }
            [self.axisLabelStrings[axis] setObject:labelText forKey:@(labelValue)];

            //Calculate the size of the label which would be created
            CGSize size = CGSizeZero;
            UIFont *font = axis == BBGraphAxisX ? self.xAxisFont : self.yAxisFont;

            // iOS 7+
            if ([labelText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
                CGRect rect = [labelText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{NSFontAttributeName : font}
                                                      context:nil];
                size = rect.size;
            }
                    // iOS < 7
            else {
                size = [labelText sizeWithFont:font
                             constrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            }

            maxLabelWidth = MAX(size.width, maxLabelWidth);
            maxLabelHeight = MAX(size.height, maxLabelHeight);
        }
        if (axis == BBGraphAxisY) {
            inset.x = maxLabelWidth + axisDataPointPadding + axisDataPointSize;
        }
        else {
            inset.y = maxLabelHeight + axisDataPointPadding + axisDataPointSize;
        }

        [self.numberOfAxisLabels setObject:@(numberOfLabels) forKey:@(axis)];
        [self.intervalOfAxisLabels setObject:@(intervalOfLabels) forKey:@(axis)];
    }

    self.graphSpaceInset = inset;
}

#pragma mark - Set Up Spaces

- (void)setUpValueSpace {
    CGFloat xSize;
    CGFloat ySize;

    xSize = self.scaleXAxisToValues ? self.highestXValue - self.lowestXValue : self.highestXValue;
    ySize = self.scaleYAxisToValues ? self.highestYValue - self.lowestYValue : self.highestYValue;

    self.valueSpace = CGRectMake(0,
            0,
            xSize,
            ySize);
}

- (void)setupGraphSpace {
    CGRect screenSpaceFrame = self.screenSpaceView.frame;
    screenSpaceFrame.origin.x += self.graphSpaceInset.x;
    screenSpaceFrame.size.width -= self.graphSpaceInset.x;
    screenSpaceFrame.size.height -= self.graphSpaceInset.y;
    self.screenSpaceView.frame = screenSpaceFrame;
    self.axisView.frame = self.screenSpaceView.frame;
}

#pragma mark - Alterations

- (void)insertSeries:(NSIndexSet *)series {

}

- (void)deleteSeries:(NSIndexSet *)series {

}

- (void)reloadSeries:(NSIndexSet *)series {

}

- (void)moveSeries:(NSInteger)series toSeries:(NSInteger)newSeries {

}

- (void)insertPointsAtIndexPaths:(NSArray *)indexPaths {

}

- (void)deletePointsAtIndexPaths:(NSArray *)indexPaths {

}

- (void)reloadPointsAtIndexPaths:(NSArray *)indexPaths {

}

- (void)movePointsAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {

}

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL finished))completion {

}

#pragma mark

- (void)layoutSubviews {
    [super layoutSubviews];
    //A good idea to impose some extra padding to accomodate axis ends etc
    self.screenSpaceView.frame = CGRectInset(self.bounds, self.xPadding, self.yPadding);
    self.axisView.frame = self.screenSpaceView.frame;
    if (!self.series) {[self populateSeries];}

    if (![self validateData])
        return;

    [self setUpValueSpace];
    [self drawGraph];
}

- (void)reloadData {
    [self populateSeries];
    if (![self validateData])
        return;
    [self setUpValueSpace];
    [self drawGraph];
}

- (BOOL)validateData {
    //If all values on an axis are the same the highest and lowest values are not set correctly.  This resolves that:
    if (self.lowestXValue == self.highestXValue) {
        if (self.lowestXValue < 0)
            self.highestXValue = 0;
        if (self.highestXValue > 0)
            self.lowestXValue = 0;

        if (self.lowestXValue < 0)
            self.highestXValue = 0;
        if (self.highestYValue > 0)
            self.lowestYValue = 0;
    }
    //Check that we have enough data to draw a graph
    return !(self.lowestXValue == self.highestXValue || self.lowestYValue == self.highestYValue);
}

#pragma mark - Drawing

- (void)drawGraph {
    //Will work out the amount of space to leave around the graph by grabbing the text for the labels
    //In order to do this we will need to grab all of the data for label text from the delegate so we
    //save that into a property for re-use later
    [self setupGraphSpace];

    //Remove the axis labels which we will redraw
    [self.labels makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if (self.displayXAxis)
        [self drawAxis:BBGraphAxisX];

    if (self.displayYAxis)
        [self drawAxis:BBGraphAxisY];

    for (NSUInteger l = 0; l < [self numberOfSeries]; l++) {
        [self drawSeries:l];
    }


}

- (void)drawAxis:(BBGraphAxis)axis {
    CGPoint startPoint = CGPointZero;
    CGPoint endPoint = CGPointZero;
    NSString *layerKey;

    if (axis == BBGraphAxisX) {
        startPoint = CGPointMake(MIN(self.lowestXValue, 0), 0);
        endPoint = CGPointMake(self.highestXValue, 0);
        layerKey = xAxisLayerKey;
    }
    else {
        startPoint = CGPointMake(0, MIN(self.lowestYValue, 0));
        endPoint = CGPointMake(0, self.highestYValue);
        layerKey = yAxisLayerKey;
    }

    if (self.scaleYAxisToValues) {
        startPoint.y -= self.lowestYValue;
        endPoint.y -= self.lowestYValue;
    }
    else {
        startPoint.y = 0;
    }
    if (self.scaleXAxisToValues) {
        startPoint.x -= self.lowestXValue;
        endPoint.x -= self.lowestXValue;
    }
    else {
        startPoint.x = 0;
    }

    CGPoint screenStartPoint = [self convertPointToScreenSpace:startPoint];
    CGPoint screenEndPoint = [self convertPointToScreenSpace:endPoint];

    UIBezierPath *seriesPath = [UIBezierPath bezierPath];
    [seriesPath moveToPoint:screenStartPoint];
    [seriesPath addLineToPoint:screenEndPoint];

    // get the layer for the series;
    CAShapeLayer *seriesLayer = [self.axisLayers objectForKey:layerKey];

    // if there isn't a series
    if (!seriesLayer) {
        // No seriesLayer found so we need to create one
        seriesLayer = [CAShapeLayer layer];
        seriesLayer.frame = self.screenSpaceView.bounds;

        // set series properties
        seriesLayer.lineJoin = kCALineJoinBevel;
        seriesLayer.lineWidth = self.axisWidth;

        // set series style
        seriesLayer.strokeColor = self.axisColor.CGColor;
        seriesLayer.fillColor = [UIColor clearColor].CGColor;

        // add the layer to the view hierarchy.  We add to self and not the screenView to prevent clipping
        [self.axisView.layer addSublayer:seriesLayer];

        // save a refrence for later;
        [self.axisLayers setObject:seriesLayer forKey:layerKey];
    }

    seriesLayer.frame = self.bounds;
    seriesLayer.path = seriesPath.CGPath;

    [self drawDataPointsOnAxis:axis];
}

- (void)drawDataPointsOnAxis:(BBGraphAxis)axis {
    //Draw series perpendicular to the Axis for labeled data points
    NSUInteger numberOfLabels = [[self.numberOfAxisLabels objectForKey:@(axis)] unsignedIntegerValue];
    CGFloat intervalOfLabels = [[self.intervalOfAxisLabels objectForKey:@(axis)] floatValue];

    if (numberOfLabels == 0)
        return;

    UIBezierPath *seriesPath = [UIBezierPath bezierPath];

    //Iterate through the number of required labels and draw the markers
    for (int i = 0; i <= numberOfLabels; i++) {
        //Calculate the value of the data point to mark
        CGFloat labelValue;
        if (axis == BBGraphAxisX)
            labelValue = self.lowestXValue + i * intervalOfLabels;
        else
            labelValue = self.lowestYValue + i * intervalOfLabels;

        labelValue -= fmodf(labelValue, intervalOfLabels);


        CGPoint axisPoint = CGPointZero;
        CGPoint endAxisPoint = CGPointZero;

        if (axis == BBGraphAxisX) {
            axisPoint = CGPointMake(labelValue, 0);
        }
        else if (axis == BBGraphAxisY) {
            axisPoint = CGPointMake(0, labelValue);
        }

        //The else if here prevents drawing label markers outside of the chart area
        if (self.scaleXAxisToValues) {
            axisPoint.x -= self.lowestXValue;
        }
        else if (axisPoint.x < 0) {
            continue;
        }
        if (self.scaleYAxisToValues) {
            axisPoint.y -= self.lowestYValue;
        }
        else if (axisPoint.y < 0) {
            continue;
        }

        axisPoint = [self convertPointToScreenSpace:axisPoint];

        endAxisPoint = axisPoint;

        if (axis == BBGraphAxisX) {
            endAxisPoint.y += axisDataPointSize;
            axisPoint.y -= 1.0f;
        }
        else if (axis == BBGraphAxisY) {
            endAxisPoint.x -= axisDataPointSize;
            axisPoint.x += 1.0f;
        }

        [seriesPath moveToPoint:axisPoint];
        [seriesPath addLineToPoint:endAxisPoint];

        //Draw the text
        [self drawLabelOnAxis:axis atValue:labelValue];
    }

    NSString *layerKey;

    if (axis == BBGraphAxisX) {
        layerKey = xAxisLayerKey;
    }
    else {
        layerKey = yAxisLayerKey;
    }

    // get the layer for the series;
    CAShapeLayer *seriesLayer = [self.axisDataPointLayers objectForKey:layerKey];

    // if there isn't a series
    if (!seriesLayer) {
        // For now we are passing in -2 for an axis data point.  There's probably a better way
        seriesLayer = [CAShapeLayer layer];
        seriesLayer.frame = self.screenSpaceView.bounds;
        seriesLayer.lineJoin = kCALineJoinBevel;
        seriesLayer.lineWidth = self.axisDataPointWidth;
        seriesLayer.strokeColor = self.axisColor.CGColor;
        seriesLayer.fillColor = [UIColor clearColor].CGColor;

        // add the layer to the view hierarchy.  We add to self and not the screenView to prevent clipping
        [self.axisView.layer addSublayer:seriesLayer];

        // save a refrence for later;
        [self.axisDataPointLayers setObject:seriesLayer forKey:layerKey];
    }

    seriesLayer.frame = self.bounds;
    seriesLayer.path = seriesPath.CGPath;
}

- (void)drawLabelOnAxis:(BBGraphAxis)axis atValue:(CGFloat)value {
    //Don't draw for 0
    if (!self.displayZeroAxisLabel && value == 0)
        return;

    NSString *labelText = self.axisLabelStrings[axis][@(value)];

    //TODO: get label text from our property

    CGRect labelRect = CGRectZero;
    UILabel *label = [[UILabel alloc] init];

    CGFloat height = 0;

    // iOS 7+
    if ([labelText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        CGRect rect = [labelText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName : self.yAxisFont}
                                              context:nil];
        height = rect.size.height;
    }
            // iOS < 7
    else {
        height = [labelText sizeWithFont:self.yAxisFont
                       constrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
    }

    [label setTextAlignment:NSTextAlignmentRight];
    CGPoint screenSpaceLabelPoint = [self convertPointToScreenSpace:
            CGPointMake(self.scaleXAxisToValues ? -self.lowestXValue : 0,
                    value - (self.scaleYAxisToValues ? self.lowestYValue : 0))];
    //The labels on the X axis will be 5% as tall as the graph area and as wide as possible
    if (axis == BBGraphAxisX) {
        [label setTextAlignment:NSTextAlignmentCenter];
        screenSpaceLabelPoint = [self convertPointToScreenSpace:
                CGPointMake(value + (self.scaleXAxisToValues ? -self.lowestXValue : 0),
                        self.scaleYAxisToValues ? -self.lowestYValue : 0)];
        CGFloat width = self.screenSpace.size.width / [[self.numberOfAxisLabels objectForKey:@(axis)] floatValue];
        labelRect = CGRectMake(screenSpaceLabelPoint.x - width / 2,
                screenSpaceLabelPoint.y + axisDataPointSize + axisDataPointPadding,
                width,
                height);

    }
    else if (axis == BBGraphAxisY) //The labels on the Y axis will be 10% the width of the graph and as tall as possible
    {

        CGFloat width = self.axisView.frame.origin.x;
        labelRect = CGRectMake(screenSpaceLabelPoint.x - width - axisDataPointPadding - axisDataPointSize,
                screenSpaceLabelPoint.y - height / 2,
                width,
                height);
    }

    label.text = labelText;
    //Get the font size that fits the label
    //TODO: Keep track of the smallest font for an axis and apply it to all of the labels on that axis (maybe we can iterate over the labels array
    //^ It should be split into a dictionary of arrays, or something similar so we can see what axis the labels are on before resizing them
    label.frame = labelRect;
    label.font = axis == BBGraphAxisX ? self.xAxisFont : self.yAxisFont;
    label.textColor = self.axisLabelColor;

    //The plan was going to be to get the font size after it adjustsFontSizeToFitWidth but the label.font doesn't seem to change
    //It may mean we have to go back to the category on UIlabel
    [self.axisView addSubview:label];
    [self.labels addObject:label];
}

- (void)drawSeries:(NSUInteger)series {
    // get the series array
    NSArray *seriesArray = self.series[series];

    // set up a bezier path
    UIBezierPath *seriesPath = [UIBezierPath bezierPath];

    BOOL curvedLine = NO;

    if ([self.delegate respondsToSelector:@selector(graph:shouldCurveSeries:)]) {
        curvedLine = [self.delegate graph:self shouldCurveSeries:series];
    }


    // loop through the values
    [seriesArray enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger pointNumber, BOOL *stop) {

        CGPoint point = pointValue.CGPointValue;

        if (self.scaleXAxisToValues)
            point.x -= self.lowestXValue;

        if (self.scaleYAxisToValues)
            point.y -= self.lowestYValue;

        // convert the values to screen
        CGPoint screenPoint = [self convertPointToScreenSpace:point];

//		NSLog(@"Value (%f,%f), Screen (%f,%f)", point.x, point.y, screenPoint.x, screenPoint.y);

        // for the first point move to point
        if (pointNumber == 0) {
            [seriesPath moveToPoint:screenPoint];
        }

                // for the rest add series to point
        else {
            [seriesPath addLineToPoint:screenPoint];

        }
    }];
    if (curvedLine)
        seriesPath = [seriesPath smoothedPathWithGranularity:self.bounds.size.width / [seriesArray count]];


    // get the layer for the series;
    CAShapeLayer *seriesLayer = [self.seriesLayers objectForKey:@(series)];

    // if there isn't a series
    if (!seriesLayer) {
        // create a layer for the series
        seriesLayer = [self styledLayerForSeries:series];

        // add the layer to the view hierarchy
        [self.screenSpaceView.layer addSublayer:seriesLayer];

        // save a refrence for later;
        [self.seriesLayers setObject:seriesLayer forKey:@(series)];
    }

    seriesLayer.frame = self.bounds;
    seriesLayer.path = seriesPath.CGPath;
}

- (CAShapeLayer *)styledLayerForSeries:(NSUInteger)series {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.screenSpaceView.bounds;

    layer.lineJoin = kCALineJoinRound;
    if ([self.delegate respondsToSelector:@selector(graph:widthForSeries:)]) {
        layer.lineWidth = [self.delegate graph:self widthForSeries:series];
    }
    else {
        layer.lineWidth = 2.f;
    }

    layer.strokeColor = [self colorForSeries:series];
    layer.fillColor = [UIColor clearColor].CGColor;

    return layer;
}

#pragma mark - Animation

- (void)animateGraph {
    for (id seriesKey in [self.seriesLayers allKeys]) {
        CAShapeLayer *seriesLayer = self.seriesLayers[seriesKey];

        NSTimeInterval animationDuration = .3f;
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.removedOnCompletion = YES;
        animation.duration = animationDuration;
        animation.fillMode = kCAFillModeForwards;

        [seriesLayer addAnimation:animation forKey:@"strokeEnd"];
    }

}

#pragma mark

- (UIView *)axisView {
    if (!_axisView) {
        _axisView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_axisView];
    }
    return _axisView;
}

- (UIView *)screenSpaceView {
    if (!_screenSpaceView) {
        _screenSpaceView = [[UIView alloc] initWithFrame:self.bounds];
        _screenSpaceView.clipsToBounds = NO;
        [self addSubview:_screenSpaceView];
    }
    _screenSpaceView.backgroundColor = self.graphBackgroundColor;
    return _screenSpaceView;
}

- (CGRect)screenSpace {
    return self.screenSpaceView.bounds;
}

- (CGPoint)convertPointToScreenSpace:(CGPoint)point {
    return CGPointApplyAffineTransform(point, [self transformFromValueToScreen]);
}

- (CGPoint)convertPointToValueSpace:(CGPoint)point {
    return CGPointApplyAffineTransform(point, [self transformFromScreenToValue]);
}

- (CGAffineTransform)transformFromValueToScreen {
    CGRect fromRect = self.valueSpace;
    CGRect viewRect = self.screenSpace;

    // get the scale delta
    CGSize scales = CGSizeMake(viewRect.size.width / fromRect.size.width,
            viewRect.size.height / fromRect.size.height);

    // set up a transform
    CGAffineTransform transform = CGAffineTransformIdentity;

    // Move origin from upper left to lower left.
    transform = CGAffineTransformTranslate(transform, 0, viewRect.size.height);

    // Flip the sign of the Y axis.
    transform = CGAffineTransformScale(transform, 1, -1);

    // Apply value-to-screen scaling.
    transform = CGAffineTransformScale(transform, scales.width, scales.height);

    return transform;
}

- (CGAffineTransform)transformFromScreenToValue {
    return CGAffineTransformInvert([self transformFromValueToScreen]);
}

- (CGFloat)roundValue:(CGFloat)number Up:(BOOL)up {
    // this dosn't work well for decimals between 0 and 1;

    double numberOfSignificentFigures = ceil(log10(fabs(number)));

    int multiple = pow(10, numberOfSignificentFigures - 1);

    int u;

    if (up) {
        u = ceil(number / multiple);
    }
    else {
        u = floor(number / multiple);
    }

    return u * multiple;
}

- (CGColorRef)colorForSeries:(NSInteger)series {
    UIColor *color = nil;

    if (series < 0) //Axis colours
    {
        color = self.axisColor;
    }
    else if ([self.delegate respondsToSelector:@selector(graph:colorForSeries:)]) //Series colours
    {
        color = [self.delegate graph:self colorForSeries:series];
    }

    if (color)
        return color.CGColor;

    return [UIColor blackColor].CGColor;
}

@end

@implementation NSIndexPath (BBLineGraph)

+ (NSIndexPath *)indexPathForPoint:(NSInteger)point inSeries:(NSInteger)series {
    return [self indexPathForItem:point inSection:series];
}

- (NSInteger)series {
    return self.section;
}

- (NSInteger)point {
    return self.item;
}

@end
