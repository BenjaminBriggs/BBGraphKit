//
//  BBBarGraph.m
//  GraphKit
//
//  Created by Palringo on 19/03/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBBarGraph.h"
#import "BBLineGraph.h"

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

@interface BBBarGraph ()

@end

@implementation BBBarGraph

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

    if ([self.delegate respondsToSelector:@selector(lineGraph:shouldCurveSeries:)]) {
//        curvedLine = [self.delegate lineGraph:self shouldCurveSeries:series];
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
        CGPoint flooredPoint = point;
        flooredPoint.y = 0;
        CGPoint screenFlooredPoint = [self convertPointToScreenSpace:flooredPoint];

        [seriesPath moveToPoint:screenFlooredPoint];
        [seriesPath addLineToPoint:screenPoint];
    }];

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

    //If animation is enabled don't draw the series yet
    if ([self.delegate respondsToSelector:@selector(barGraph:animationDurationForSeries:)]) {
        [self animateGraph];
    }
    seriesLayer.frame = self.bounds;
    seriesLayer.path = seriesPath.CGPath;
}

- (CAShapeLayer *)styledLayerForSeries:(NSUInteger)series {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = self.screenSpaceView.bounds;

    layer.lineJoin = kCALineJoinRound;
    if ([self.delegate respondsToSelector:@selector(barGraph:widthForSeries:)]) {
        layer.lineWidth = [self.delegate barGraph:self
                                   widthForSeries:series];
    }
    else {
        layer.lineWidth = 20.f;
    }

    layer.strokeColor = [self colorForSeries:series];
    layer.fillColor = [UIColor clearColor].CGColor;

    return layer;
}

#pragma mark - Animation

- (void)animateGraph {
    if (![self.delegate respondsToSelector:@selector(barGraph:animationDurationForSeries:)])
        return;
    for (id seriesKey in [self.seriesLayers allKeys]) {
        CAShapeLayer *seriesLayer = self.seriesLayers[seriesKey];

        NSTimeInterval animationDuration = [self.delegate barGraph:self
                                        animationDurationForSeries:[seriesKey unsignedIntegerValue]];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.removedOnCompletion = YES;
        animation.duration = animationDuration;
        animation.fillMode = kCAFillModeForwards;

        [seriesLayer addAnimation:animation forKey:@"strokeEnd"];
    }

}

@end
