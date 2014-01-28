//
//  BBLineGraph.m
//  GraphKit
//
//  Created by Benjamin Briggs on 27/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBLineGraph.h"

@interface BBLineGraph ()

@property (nonatomic, strong) NSArray *lines; // an array of arrays of nsvalues for cgpoints
@property (nonatomic, strong) NSMutableDictionary *lineLayers; //an array of calayers;

@property (nonatomic, assign) CGRect valueSpace;
@property (nonatomic, assign) CGRect screenSpace;

@property (nonatomic, strong) UIView *screenSpaceView;

@property (nonatomic, assign) CGFloat highestYValue;
@property (nonatomic, assign) CGFloat highestXValue;

@property (nonatomic, assign) CGFloat lowestYValue;
@property (nonatomic, assign) CGFloat lowestXValue;

@end

@implementation BBLineGraph

- (UIView *)screenSpaceView
{
	if (!_screenSpaceView)
    {
		_screenSpaceView = [[UIView alloc] initWithFrame:self.bounds];
		_screenSpaceView.backgroundColor = [UIColor lightGrayColor];
		[self addSubview:_screenSpaceView];
	}
	return _screenSpaceView;
}

- (CGRect)screenSpace
{
	return self.screenSpaceView.bounds;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.screenSpaceView.frame = CGRectInset(self.bounds, 10, 10);
    
	if (!self.lines) { [self populateLines]; }
    
	[self setUpValueSpace];
	[self drawLines];
    
	// Just for dev
	self.layer.borderColor = [UIColor redColor].CGColor;
	self.layer.borderWidth = 1.f;
}

- (void)reloadData
{
	[self populateLines];
	[self setUpValueSpace];
	[self drawLines];
}

- (void)populateLines
{
	// get the number of lines in the graph
	NSInteger numberOfLines = 1;
    
	// check if the data source provided a number of lines
	if ([self.dataSource respondsToSelector:@selector(numberOfLinesInLineGraph:)])
    {
		numberOfLines = [self.dataSource numberOfLinesInLineGraph:self];
    }
    
	// set up some holders fpr the high and low values
	CGFloat highestYValue = -MAXFLOAT;
	CGFloat highestXValue = -MAXFLOAT;
    
	CGFloat lowestYValue = MAXFLOAT;
	CGFloat lowestXValue = MAXFLOAT;
    
	// create an array to holder the lines
	NSMutableArray *lines = [NSMutableArray arrayWithCapacity:numberOfLines];
    
	// loop to get the lines
	for (NSInteger l = 0; l < numberOfLines; l++)
    {
        
		// check how many points are in this line
		NSInteger numberOfPoints = [self.dataSource lineGraph:self
										 numberOfPointsInLine:l];
        
		// create an array to hold the points
		NSMutableArray *points = [NSMutableArray arrayWithCapacity:numberOfPoints];
        
		// loop to get the points for this line
		for (NSInteger p = 0; p < numberOfPoints; p++)
        {
            
			// get the point from the data source
			CGPoint point = [self.dataSource lineGraph:self
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
		if (self.orderedAxis == BBLineGraphAxisX)
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
	self.lines = lines;
    
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

- (void)drawLines
{
	// just a convients call to draw each line
	for (NSInteger l = 0; l < [self numberOfLines]; l++)
    {
		[self drawLine:l];
    }
}

- (void)drawLine:(NSInteger)line
{
	// get the line array
	NSArray *lineArray =  self.lines[line];
    
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
    
	layer.lineWidth = 2.f;
	layer.lineJoin = kCALineJoinRound;
    
	layer.strokeColor = [UIColor redColor].CGColor;
	layer.fillColor = [UIColor clearColor].CGColor;
    
	return layer;
}

#pragma mark - Helpers


- (NSInteger)numberOfLines
{
	return self.lines.count;
}

- (NSInteger)numberOfPointsInLine:(NSInteger)line
{
	if (line <= 0 && line > self.lines.count)
    {
		NSArray *points = self.lines[line];
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