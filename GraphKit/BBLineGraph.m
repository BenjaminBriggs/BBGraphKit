//
//  BBLineGraph.m
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBLineGraph.h"
#import "BBGraph+SubclassingHooks.h"
#import "UILabel+BBGraphKit.h"

@interface BBLineGraph ()

@property (nonatomic, strong) NSMutableDictionary *lineLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *axisDataPointLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *numberOfAxisLabels; //A number of labels per axis where the key is a BBLineGraphAxis enum
@property (nonatomic, strong) NSMutableDictionary *intervalOfAxisLabels; //The interval to display axis labels

@property (nonatomic, strong) NSMutableArray *labels;

@property (nonatomic, assign) CGRect valueSpace;
@property (nonatomic, assign) CGRect screenSpace;

@property (nonatomic, strong) UIView *screenSpaceView;

@property (nonatomic, assign) CGFloat highestYValue;
@property (nonatomic, assign) CGFloat highestXValue;

@property (nonatomic, assign) CGFloat lowestYValue;
@property (nonatomic, assign) CGFloat lowestXValue;

@end

NSString *const xAxisLayerKey = @"xAxisLayer";
NSString *const yAxisLayerKey = @"yAxisLayer";

CGFloat const axisDataPointSize = 5.f;
CGFloat const axisDataPointPadding = 1.f;

@implementation BBLineGraph
@synthesize series = _series;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}


- (void)commonInit
{
    _lineLayers = [NSMutableDictionary dictionary];
    _axisDataPointLayers = [NSMutableDictionary dictionary];
    _numberOfAxisLabels = [NSMutableDictionary dictionary];
    _intervalOfAxisLabels = [NSMutableDictionary dictionary];
    
    //Defaults
    self.axisDataPointWidth = 1.0f;
    self.axisWidth = 2.0f;
    _scaleYAxisToValues = YES;
    _scaleXAxisToValues = YES;
    _displayXAxis = YES;
    _displayYAxis = YES;
}

- (UIView *)screenSpaceView
{
	if (!_screenSpaceView)
    {
		_screenSpaceView = [[UIView alloc] initWithFrame:self.bounds];
        _screenSpaceView.clipsToBounds = YES;
		[self addSubview:_screenSpaceView];
	}
    _screenSpaceView.backgroundColor = self.graphBackgroundColor;
	return _screenSpaceView;
}

- (CGRect)screenSpace
{
	return self.screenSpaceView.bounds;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	if (!self.series) { [self populateSeries]; }
    
	[self setUpValueSpace];
	[self drawGraph];
}

- (void)reloadData
{
	[self populateSeries];
	[self setUpValueSpace];
	[self drawGraph];
}

- (void)populateSeries
{
	// get the number of lines in the graph
	NSInteger numberOfSeries = 1;
    
	// check if the data source provided a number of lines
	if ([self.dataSource respondsToSelector:@selector(numberOfSeriesInGraph:)])
    {
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
	for (NSInteger l = 0; l < numberOfSeries; l++)
    {
        
		// check how many points are in this line
		CGFloat numberOfPoints = [self.dataSource graph:self
										 numberOfPointsInSeries:l];
        
		// create an array to hold the points
		NSMutableArray *points = [NSMutableArray arrayWithCapacity:numberOfPoints];
        
		// loop to get the points for this line
		for (NSInteger p = 0; p < numberOfPoints; p++)
        {
            
			// get the point from the data source
			CGPoint point = [self.dataSource graph:self
								  valueForPointAtIndex:[NSIndexPath indexPathForPoint:p
																			   inLine:l]];
            
			// added it to the points array
			[points addObject:[NSValue valueWithCGPoint:point]];
            
			// get the highest and lowest values in the data set;
			highestYValue = MAX(highestYValue, point.y);
			highestXValue = MAX(highestXValue, point.x);
            
			lowestYValue = MIN(lowestYValue, point.y);
			lowestXValue = MIN(lowestXValue, point.x);
            
        }
        
		// sort the line
		if (self.orderedAxis == BBGraphAxisX)
        {
			[points sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				if ([obj1 CGPointValue].x > [obj2 CGPointValue].x) {
					return (NSComparisonResult)NSOrderedDescending;
				}
                
				if ([obj1 CGPointValue].x < [obj2 CGPointValue].x) {
					return (NSComparisonResult)NSOrderedAscending;
				}
				return (NSComparisonResult)NSOrderedSame;
			}];
        }
		else
        {
			[points sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				if ([obj1 CGPointValue].y > [obj2 CGPointValue].y) {
					return (NSComparisonResult)NSOrderedDescending;
				}
                
				if ([obj1 CGPointValue].y < [obj2 CGPointValue].y) {
					return (NSComparisonResult)NSOrderedAscending;
				}
				return (NSComparisonResult)NSOrderedSame;
			}];
        }
        
		// add the array of points to the lines array, still with me?
		[lines addObject:points];
    }
    
	// save the lines array
	self.series = lines;
    
	// finaly save the high and low values
	_highestYValue = highestYValue;
	_highestXValue = highestXValue;
    
	_lowestYValue = lowestYValue;
	_lowestXValue = lowestXValue;
}

- (void)setUpValueSpace
{
    CGFloat xSize;
    CGFloat ySize;
    
    xSize = _scaleXAxisToValues ? _highestXValue - _lowestXValue : _highestXValue;
    ySize = _scaleYAxisToValues ? _highestYValue - _lowestYValue : _highestYValue;

	self.valueSpace = CGRectMake(0,
								 0,
								 xSize,
								 ySize);
}

- (void)drawGraph
{
    if (_displayXAxis)
        [self drawAxis:BBGraphAxisX];
    
    if (_displayYAxis)
        [self drawAxis:BBGraphAxisY];
    
    for (NSInteger l = 0; l < [self numberOfLines]; l++)
    {
		[self drawLine:l];
    }
    

}

-(void)drawAxis:(BBGraphAxis)axis
{
    CGPoint startPoint;
    CGPoint endPoint;
    NSString *layerKey;
    
    if (axis == BBGraphAxisX)
    {
        startPoint = CGPointMake(MIN(_lowestXValue, 0), 0);
        endPoint = CGPointMake(_highestXValue, 0);
        layerKey = xAxisLayerKey;
    }
    else if (axis == BBGraphAxisY)
    {
        startPoint = CGPointMake(0, MIN(_lowestYValue, 0));
        endPoint = CGPointMake(0, _highestYValue);
        layerKey = yAxisLayerKey;
    }
    
    if (_scaleYAxisToValues)
    {
        startPoint.y -= _lowestYValue;
        endPoint.y -= _lowestYValue;
    }
    else
    {
        startPoint.y = 0;
    }
    if (_scaleXAxisToValues)
    {
        startPoint.x -= _lowestXValue;
        endPoint.x -= _lowestXValue;
    }
    else
    {
        startPoint.x = 0;
    }
    
    CGPoint screenStartPoint = [self convertPointToScreenSpace:startPoint];
    CGPoint screenEndPoint = [self convertPointToScreenSpace:endPoint];
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:screenStartPoint];
    [linePath addLineToPoint:screenEndPoint];
    
    // get the layer for the line;
	CAShapeLayer *lineLayer = [self.lineLayers objectForKey:layerKey];
    
	// if there isn't a line
	if (!lineLayer)
    {
		// For now we are passing in -1 for an axis.  There's probably a better way
		lineLayer = [self styledLayerForLine:-1];
        
		// add the layer to the view hierarchy.  We add to self and not the screenView to prevent clipping
		[self.layer addSublayer:lineLayer];
        
		// save a refrence for later;
		[self.lineLayers setObject:lineLayer forKey:layerKey];
    }
    
	// you could animate these
	lineLayer.frame = self.screenSpaceView.frame;
	lineLayer.path = linePath.CGPath;
    
    [self drawAxisDataPointsOnAxis:axis];
}

- (void)drawAxisDataPointsOnAxis:(BBGraphAxis)axis
{
    //Draw lines perpendicular to the Axis for labeled data points
    NSUInteger numberOfLabels = 0;
    CGFloat intervalOfLabels = 0;
    
    //Get the information from the data source required to calculate & draw these
    if ([self.dataSource respondsToSelector:@selector(graph:intervalOfLabelsForAxis:)])
    {
        intervalOfLabels = [self.dataSource graph:self intervalOfLabelsForAxis:axis];
        if(axis == BBGraphAxisX)
        {
            numberOfLabels = floor((_highestXValue - _lowestXValue) / intervalOfLabels);
        }
        else if (axis == BBGraphAxisY)
        {
            numberOfLabels = floor((_highestYValue - _lowestYValue) / intervalOfLabels);
            
        }
    }
    else if ([self.dataSource respondsToSelector:@selector(graph:numberOfLabelsForAxis:)])
    {
        numberOfLabels = [self.dataSource graph:self numberOfLabelsForAxis:axis];
        if(axis == BBGraphAxisX)
        {
            intervalOfLabels = (_highestXValue - _lowestXValue) / numberOfLabels;
        }
        else if (axis == BBGraphAxisY)
        {
            intervalOfLabels = (_highestYValue - _lowestYValue) / numberOfLabels;
            
        }
    }
    [_numberOfAxisLabels setObject:@(numberOfLabels) forKey:@(axis)];
    [_intervalOfAxisLabels setObject:@(intervalOfLabels) forKey:@(axis)];
    
    if(numberOfLabels == 0)
        return;
    
    UIBezierPath *linePath = [UIBezierPath bezierPath];

    //Iterate through the number of required labels and draw the markers
    for(int i = 0; i <= numberOfLabels; i++)
    {
        //Calculate the value of the data point to mark
        CGFloat labelValue;
        if (axis == BBGraphAxisX)
            labelValue = _lowestXValue + i * intervalOfLabels;
        else if (axis == BBGraphAxisY)
            labelValue = _lowestYValue + i * intervalOfLabels;
        
        
        CGPoint axisPoint;
        CGPoint endAxisPoint;
        
        if (axis == BBGraphAxisX)
        {
            axisPoint = CGPointMake(labelValue, 0);
        }
        else if (axis == BBGraphAxisY)
        {
            axisPoint = CGPointMake(0, labelValue);
        }
        
        //The else if here prevents drawing label markers outside of the chart area
        if (_scaleXAxisToValues)
        {
            axisPoint.x -= _lowestXValue;
        }
        else if (axisPoint.x < 0)
        {
            continue;
        }
        if (_scaleYAxisToValues)
        {
            axisPoint.y -= _lowestYValue;
        }
        else if (axisPoint.y < 0)
        {
            continue;
        }
        
        axisPoint = [self convertPointToScreenSpace:axisPoint];
        
        endAxisPoint = axisPoint;
        
        if (axis == BBGraphAxisX)
        {
            endAxisPoint.y += axisDataPointSize;
            axisPoint.y -= 1.0f;
        }
        else if (axis == BBGraphAxisY)
        {
            endAxisPoint.x -= axisDataPointSize;
            axisPoint.x += 1.0f;
        }
        
        [linePath moveToPoint:axisPoint];
        [linePath addLineToPoint:endAxisPoint];
        
        //Draw the text
        [self drawLabelOnAxis:axis atValue:labelValue];
    }
    
    NSString *layerKey;
    
    if (axis == BBGraphAxisX)
    {
        layerKey = xAxisLayerKey;
    }
    else if (axis == BBGraphAxisY)
    {
        layerKey = yAxisLayerKey;
    }
    
    // get the layer for the line;
	CAShapeLayer *lineLayer = [self.axisDataPointLayers objectForKey:layerKey];
    
	// if there isn't a line
	if (!lineLayer)
    {
		// For now we are passing in -2 for an axis data point.  There's probably a better way
		lineLayer = [self styledLayerForLine:-2];
        
		// add the layer to the view hierarchy.  We add to self and not the screenView to prevent clipping
		[self.layer addSublayer:lineLayer];
        
		// save a refrence for later;
		[self.axisDataPointLayers setObject:lineLayer forKey:layerKey];
    }
    
	// you could animate these
	lineLayer.frame = self.screenSpaceView.frame;
	lineLayer.path = linePath.CGPath;
}

- (void)drawLabelOnAxis:(BBGraphAxis)axis atValue:(CGFloat)value
{
    //Don't draw for 0
    if (!_displayZeroAxisLabel && value == 0)
        return;
    /* When we come to draw the label text we will use either the value or something like:
     - (NSString *)lineGraph:(BBLineGraph *)lineGraph stringForLabelAtValue:(NSInteger)value onAxis:(BBLineGraphAxis)axis; */
    NSString *labelText;
    if([self.delegate respondsToSelector:@selector(graph:stringForLabelAtValue:onAxis:)])
    {
        labelText = [self.delegate graph:self stringForLabelAtValue:value onAxis:axis];
    }
    else
    {
        labelText = [NSString stringWithFormat:@"%g", value];
    }
    CGRect labelRect;
    CGPoint screenSpaceLabelPoint;
    UILabel *label = [[UILabel alloc] init];

    //The labels on the X axis will be 5% as tall as the graph area and as wide as possible
    if (axis == BBGraphAxisX)
    {
        [label setTextAlignment:NSTextAlignmentCenter];
        screenSpaceLabelPoint = [self convertPointToScreenSpace:
                                 CGPointMake(value + (_scaleXAxisToValues ? - _lowestXValue : 0),
                                             _scaleYAxisToValues ? - _lowestYValue : 0)];
        CGFloat width = self.screenSpace.size.width / [[_numberOfAxisLabels objectForKey:@(axis)] floatValue];
        labelRect = CGRectMake(screenSpaceLabelPoint.x - width / 2,
                               screenSpaceLabelPoint.y + axisDataPointSize + axisDataPointPadding,
                               width,
                               self.screenSpace.size.height * .05);
        
    }
    else if (axis == BBGraphAxisY) //The labels on the Y axis will be 10% the width of the graph and as tall as possible
    {
        [label setTextAlignment:NSTextAlignmentRight];
        screenSpaceLabelPoint = [self convertPointToScreenSpace:
                                 CGPointMake(_scaleXAxisToValues ? - _lowestXValue : 0,
                                             value - (_scaleYAxisToValues ?  _lowestYValue : 0))];
        CGFloat height = self.screenSpace.size.height / [[_numberOfAxisLabels objectForKey:@(axis)] floatValue];
        labelRect = CGRectMake(screenSpaceLabelPoint.x - self.screenSpace.size.width * .1,
                               screenSpaceLabelPoint.y - height / 2,
                               self.screenSpace.size.width * .1 - axisDataPointSize - axisDataPointPadding,
                               height);
    }
    
    label.text = labelText;
    //Get the font size that fits the label
    //TODO: Keep track of the smallest font for an axis and apply it to all of the labels on that axis (maybe we can iterate over the labels array
    //^ It should be split into a dictionary of arrays, or something similar so we can see what axis the labels are on before resizing them
    [label sizeLabelToRect:labelRect];
    
    [self addSubview:label];
    [self.labels addObject:label];
}

- (void)drawLine:(NSInteger)line
{
	// get the line array
	NSArray *lineArray =  self.series[line];
    
	// set up a bezier path
	UIBezierPath *linePath = [UIBezierPath bezierPath];
    
	// loop through the values
	[lineArray enumerateObjectsUsingBlock:^(NSValue	*pointValue, NSUInteger pointNumber, BOOL *stop) {
        
        CGPoint point = pointValue.CGPointValue;
        
        if (_scaleXAxisToValues)
            point.x -= _lowestXValue;
        
        if (_scaleYAxisToValues)
            point.y -= _lowestYValue;
        
		// convert the values to screen
		CGPoint screenPoint = [self convertPointToScreenSpace:point];
        
		NSLog(@"Value (%f,%f), Screen (%f,%f)", point.x, point.y, screenPoint.x, screenPoint.y);
        
		// for the first point move to point
		if (pointNumber == 0)
        {
			[linePath moveToPoint:screenPoint];
        }
        
		// for the rest add line to point
		else
        {
			[linePath addLineToPoint:screenPoint];
        }
	}];
    
	// get the layer for the line;
	CAShapeLayer *lineLayer = [self.lineLayers objectForKey:@(line)];
    
	// if there isn't a line
	if (!lineLayer)
    {
		// create a layer for the line;
		lineLayer = [self styledLayerForLine:line];
        
		// add the layer to the view hierarchy
		[self.screenSpaceView.layer addSublayer:lineLayer];
        
		// save a refrence for later;
		[self.lineLayers setObject:lineLayer forKey:@(line)];
    }
    
	// you could animate these
	lineLayer.frame = self.bounds;
	lineLayer.path = linePath.CGPath;
}

- (CAShapeLayer *)styledLayerForLine:(NSInteger)line
{
	CAShapeLayer *layer = [CAShapeLayer layer];
	layer.frame = self.screenSpaceView.bounds;
    
    if(line == -2)
    {
        layer.lineWidth = self.axisDataPointWidth;
    }
    else if(line == -1)
    {
        layer.lineWidth = self.axisWidth;
    }
    else
    {
        if([self.delegate respondsToSelector:@selector(lineGraph:widthForLine:)])
        {
            layer.lineWidth = [self.delegate lineGraph:self widthForLine:line];
        }
        else
        {
            layer.lineWidth = 2.f;
        }
    }
	layer.lineJoin = kCALineJoinRound;
    
	layer.strokeColor = [self colorForLine:line];
	layer.fillColor = [UIColor clearColor].CGColor;
    
	return layer;
}

#pragma mark - Helpers

-(CGColorRef)colorForLine:(NSInteger)line
{
    UIColor *color = nil;
    
    if(line < 0) //Axis colours
    {
        color = self.axisColor;
    }
    else if ([self.delegate respondsToSelector:@selector(graph:colorForSeries:)]) //Series colours
    {
        color = [self.delegate graph:self colorForSeries:line];
    }
    
    if (color)
        return color.CGColor;
    
    return [UIColor blackColor].CGColor;
}
- (NSInteger)numberOfLines
{
	return self.series.count;
}

- (NSInteger)numberOfPointsInLine:(NSInteger)line
{
	if (line <= 0 && line > self.series.count)
    {
		NSArray *points = self.series[line];
		return points.count;
    }
	else
    {
		return 0;
    }
}

- (CGPoint)convertPointToScreenSpace:(CGPoint)point
{
	return CGPointApplyAffineTransform(point, [self transformFromValueToScreen]);
}

- (CGPoint)convertPointToValueSpace:(CGPoint)point
{
	return CGPointApplyAffineTransform(point, [self transformFromScreenToValue]);
}

- (CGAffineTransform)transformFromValueToScreen
{
	CGRect fromRect = self.valueSpace;
	CGRect viewRect = self.screenSpace;
    
    // get the scale delta
	CGSize scales = CGSizeMake(viewRect.size.width/fromRect.size.width,
							   viewRect.size.height/fromRect.size.height);
    
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

- (CGAffineTransform)transformFromScreenToValue
{
	return CGAffineTransformInvert([self transformFromValueToScreen]);
}

@end

@implementation NSIndexPath (BBLineGraph)

+ (NSIndexPath *)indexPathForPoint:(NSInteger)point inLine:(NSInteger)line
{
	return [self indexPathForItem:point inSection:line];
}

- (NSInteger)line
{
	return self.section;
}

- (NSInteger)point
{
	return self.item;
}

@end