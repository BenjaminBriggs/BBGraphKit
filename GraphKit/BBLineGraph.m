//
//  BBLineGraph.m
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBLineGraph.h"
#import "BBGraph+SubclassingHooks.h"
#import <tgmath.h>

@interface BBLineGraph ()

@property (nonatomic, strong) NSMutableDictionary *lineLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *axisDataPointLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *axisLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *numberOfAxisLabels; //A number of labels per axis where the key is a BBLineGraphAxis enum
@property (nonatomic, strong) NSMutableDictionary *intervalOfAxisLabels; //The interval to display axis labels

@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) NSMutableArray *axisLabelStrings; //Array of dictionaries containing the strings for each axis [BBLineGraphAxis][@(value)]

@property (nonatomic, assign) CGRect valueSpace;
@property (nonatomic, assign) CGRect screenSpace;

@property (nonatomic, strong) UIView *screenSpaceView;
@property (nonatomic, strong) UIView *axisView;

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
@synthesize yAxisFont = _yAxisFont;
@synthesize xAxisFont = _xAxisFont;
@synthesize xPadding = _xPadding;
@synthesize yPadding = _yPadding;

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
    _axisLayers = [NSMutableDictionary dictionary];
    _numberOfAxisLabels = [NSMutableDictionary dictionary];
    _intervalOfAxisLabels = [NSMutableDictionary dictionary];
    
    //Defaults
    self.axisDataPointWidth = 1.0f;
    self.axisWidth = 2.0f;
    _scaleYAxisToValues = YES;
    _scaleXAxisToValues = YES;
    _displayXAxis = YES;
    _displayYAxis = YES;
    _xAxisFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    _yAxisFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    _xPadding = 10.f;
    _yPadding = 10.f;
}

- (UIView *)axisView
{
    if(!_axisView)
    {
        _axisView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_axisView];
    }
    return _axisView;
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
    //A good idea to impose some extra padding to accomodate axis ends etc
    self.screenSpaceView.frame = CGRectInset(self.bounds, self.xPadding, self.yPadding);
    self.axisView.frame = self.screenSpaceView.frame;
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
    //Will work out the amount of space to leave around the graph by grabbing the text for the labels
    //In order to do this we will need to grab all of the data for label text from the delegate so we
    //save that into a property for re-use later
    [self setupGraphSpace];
    
    if (_displayXAxis)
        [self drawAxis:BBGraphAxisX];
    
    if (_displayYAxis)
        [self drawAxis:BBGraphAxisY];
    
    for (NSInteger l = 0; l < [self numberOfLines]; l++)
    {
		[self drawLine:l];
    }
    

}

- (void)setupGraphSpace
{
    //At present we add the padding regardless of whether or not scale(x/y)AxisToValues is set to yes
    //We should only pad the graph if the values would otherwise not fit within the bounds of the graph
    //TODO: Implement ^ OR add a property to force the axis labels to sit outside of graph space (maybe preferred
    //as should be easier to implement)

    _axisLabelStrings = [NSMutableArray array];
    
    CGSize insets = CGSizeZero;
    
    for(int i = 0; i < 2; i++) //Iterate over the axis type enum which we know contains to types
    {
        BBGraphAxis axis = (BBGraphAxis)i;
        CGFloat maxLabelWidth = 0.f;
        CGFloat maxLabelHeight = 0.f;
        
        //Get the number & interval of axis labels
        NSUInteger numberOfLabels = 0;
        CGFloat intervalOfLabels = 0.f;
        
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
        
        //Iterate through the labels and find their associated strings
        for(int j = 0; j <= numberOfLabels; j++)
        {
            NSString *labelText;
            //Calculate the value of the label we need
            CGFloat labelValue;
            if (axis == BBGraphAxisX)
                labelValue = _lowestXValue + j * intervalOfLabels;
            else
                labelValue = _lowestYValue + j * intervalOfLabels;
            
            labelValue -= fmodf(labelValue, intervalOfLabels);
            
            if([self.delegate respondsToSelector:@selector(graph:stringForLabelAtValue:onAxis:)])
            {
                labelText = [self.delegate graph:self stringForLabelAtValue:labelValue onAxis:axis];
            }
            else
            {
                labelText = [NSString stringWithFormat:@"%g", labelValue];
            }
            
            //Save the label to a property to prevent calling the above delegate method more than once per label per reload
            if(j == 0)
            {
                [_axisLabelStrings addObject:[NSMutableDictionary dictionary]];
            }
            [_axisLabelStrings[axis] setObject:labelText forKey:@(labelValue)];
            
            //Calculate the size of the label which would be created
            CGSize size = CGSizeZero;
            UIFont *font = axis == BBGraphAxisX ? _xAxisFont : _yAxisFont;
            
            // iOS 7+
            if ([labelText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
            {
                CGRect rect = [labelText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{NSFontAttributeName:font}
                                                      context:nil];
                size = rect.size;
            }
            // iOS < 7
            else
            {
                size = [labelText sizeWithFont:font
                             constrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
            }
            
            maxLabelWidth = MAX(size.width, maxLabelWidth);
            maxLabelHeight = MAX(size.height, maxLabelHeight);
        }
        if (axis == BBGraphAxisY)
        {
            insets.width = maxLabelWidth + axisDataPointPadding + axisDataPointSize;
        }
        else
        {
            insets.height = maxLabelHeight + axisDataPointPadding + axisDataPointSize;
        }
        
        [_numberOfAxisLabels setObject:@(numberOfLabels) forKey:@(axis)];
        [_intervalOfAxisLabels setObject:@(intervalOfLabels) forKey:@(axis)];
    }
    CGRect screenSpaceFrame = self.screenSpaceView.frame;
    screenSpaceFrame.origin.x += insets.width;
    screenSpaceFrame.size.width -= insets.width;
    screenSpaceFrame.size.height -= insets.height;
    self.screenSpaceView.frame = screenSpaceFrame;
    self.axisView.frame = screenSpaceFrame;
    

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
	CAShapeLayer *lineLayer = [self.axisLayers objectForKey:layerKey];
    
	// if there isn't a line
	if (!lineLayer)
    {
		// For now we are passing in -1 for an axis.  There's probably a better way
		lineLayer = [self styledLayerForLine:-1];
        
		// add the layer to the view hierarchy.  We add to self and not the screenView to prevent clipping
		[self.axisView.layer addSublayer:lineLayer];
        
		// save a refrence for later;
		[self.axisLayers setObject:lineLayer forKey:layerKey];
    }
    
	lineLayer.frame = self.bounds;
	lineLayer.path = linePath.CGPath;
    
    [self drawDataPointsOnAxis:axis];
}

- (void)drawDataPointsOnAxis:(BBGraphAxis)axis
{
    //Draw lines perpendicular to the Axis for labeled data points
    NSUInteger numberOfLabels = [[_numberOfAxisLabels objectForKey:@(axis)] unsignedIntegerValue];
    CGFloat intervalOfLabels = [[_intervalOfAxisLabels objectForKey:@(axis)] floatValue];
    
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
        else
            labelValue = _lowestYValue + i * intervalOfLabels;
        
        labelValue -= fmodf(labelValue, intervalOfLabels);
        
        
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
		[self.axisView.layer addSublayer:lineLayer];
        
		// save a refrence for later;
		[self.axisDataPointLayers setObject:lineLayer forKey:layerKey];
    }
    
	lineLayer.frame = self.bounds;
	lineLayer.path = linePath.CGPath;
}

- (void)drawLabelOnAxis:(BBGraphAxis)axis atValue:(CGFloat)value
{
    //Don't draw for 0
    if (!_displayZeroAxisLabel && value == 0)
        return;

    NSString *labelText = _axisLabelStrings[axis][@(value)];

    //TODO: get label text from our property
    
    CGRect labelRect;
    CGPoint screenSpaceLabelPoint;
    UILabel *label = [[UILabel alloc] init];
    
    CGFloat height;
    // iOS 7+
    if ([labelText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
    {
        CGRect rect = [labelText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:_yAxisFont}
                                              context:nil];
        height = rect.size.height;
    }
    // iOS < 7
    else
    {
        height = [labelText sizeWithFont:_yAxisFont
                       constrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
    }
    
    [label setTextAlignment:NSTextAlignmentRight];
    screenSpaceLabelPoint = [self convertPointToScreenSpace:
                             CGPointMake(_scaleXAxisToValues ? - _lowestXValue : 0,
                                         value - (_scaleYAxisToValues ?  _lowestYValue : 0))];
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
    label.font = axis == BBGraphAxisX ? _xAxisFont : _yAxisFont;
    
    //The plan was going to be to get the font size after it adjustsFontSizeToFitWidth but the label.font doesn't seem to change
    //It may mean we have to go back to the category on UIlabel
    [self.axisView addSubview:label];
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
    
    //If animation is enabled don't draw the line yet
    if([self.delegate respondsToSelector:@selector(lineGraph:animationDurationForLine:)])
    {
        [self animateGraph];
    }
	lineLayer.frame = self.bounds;
	lineLayer.path = linePath.CGPath;
}

- (CAShapeLayer *)styledLayerForLine:(NSInteger)line
{
	CAShapeLayer *layer = [CAShapeLayer layer];
	layer.frame = self.screenSpaceView.bounds;
    
    if(line == -2)
    {
        layer.lineJoin = kCALineJoinBevel;
        layer.lineWidth = self.axisDataPointWidth;
    }
    else if(line == -1)
    {
        layer.lineJoin = kCALineJoinBevel;
        layer.lineWidth = self.axisWidth;
    }
    else
    {
        layer.lineJoin = kCALineJoinRound;
        if([self.delegate respondsToSelector:@selector(lineGraph:widthForLine:)])
        {
            layer.lineWidth = [self.delegate lineGraph:self widthForLine:line];
        }
        else
        {
            layer.lineWidth = 2.f;
        }
    }
    
	layer.strokeColor = [self colorForLine:line];
	layer.fillColor = [UIColor clearColor].CGColor;
    
	return layer;
}

#pragma mark - Animation

- (void)animateGraph
{
    if(![self.delegate respondsToSelector:@selector(lineGraph:animationDurationForLine:)])
        return;
    for(id lineKey in [_lineLayers allKeys])
    {
        CAShapeLayer *lineLayer = _lineLayers[lineKey];
        
        NSTimeInterval animationDuration = [self.delegate lineGraph:self animationDurationForLine:[lineKey integerValue]];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @(0);
        animation.toValue = @(1);
        animation.removedOnCompletion = YES;
        animation.duration = animationDuration;
        animation.fillMode = kCAFillModeForwards;
        
        [lineLayer addAnimation:animation forKey:@"strokeEnd"];
    }

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