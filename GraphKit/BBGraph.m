//
//  BBGraph.m
//  GraphKit
//
//  Created by Stephen Groom on 29/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraph.h"

@interface BBGraph ()

@property (nonatomic, strong) NSMutableDictionary *lineLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *axisDataPointLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *axisLayers; //an array of calayers;
@property (nonatomic, strong) NSMutableDictionary *numberOfAxisLabels; //A number of labels per axis where the key is a BBLineGraphAxis enum
@property (nonatomic, strong) NSMutableDictionary *intervalOfAxisLabels; //The interval to display axis labels

@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) NSMutableArray *axisLabelStrings; //Array of dictionaries containing the strings for each axis [BBLineGraphAxis][@(value)]

@property (nonatomic, strong) NSArray *series; // an array of arrays of nsvalues for cgpoints

@property (nonatomic, assign) CGRect valueSpace;
@property (nonatomic, assign) CGRect screenSpace;

@property (nonatomic, assign) CGFloat highestYValue;
@property (nonatomic, assign) CGFloat highestXValue;

@property (nonatomic, assign) CGFloat lowestYValue;
@property (nonatomic, assign) CGFloat lowestXValue;

@property (nonatomic, assign) CGPoint graphSpaceInset;

@property (nonatomic, strong) UIView *screenSpaceView;
@property (nonatomic, strong) UIView *axisView;

- (void)setUpValueSpace;
- (void)setupGraphSpace;

- (void)populateSeries;

@end

CGFloat const axisDataPointSize = 5.f;
CGFloat const axisDataPointPadding = 1.f;

NSString *const xAxisLayerKey = @"xAxisLayer";
NSString *const yAxisLayerKey = @"yAxisLayer";

@implementation BBGraph

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

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
    self.lineLayers = [NSMutableDictionary dictionary];
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
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        self.xAxisFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        self.yAxisFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    }
    else
    {
        self.xAxisFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        self.yAxisFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    self.xPadding = 10.f;
    self.yPadding = 10.f;
    
    
    self.axisColor = [UIColor blackColor];
}


- (NSInteger)numberOfSeries
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

#pragma mark - Create Data Structure

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
        [points sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if (self.orderedAxis == BBGraphAxisX)
            {
				if ([obj1 CGPointValue].x > [obj2 CGPointValue].x) {
					return (NSComparisonResult)NSOrderedDescending;
				}
                
				if ([obj1 CGPointValue].x < [obj2 CGPointValue].x) {
					return (NSComparisonResult)NSOrderedAscending;
				}
				return (NSComparisonResult)NSOrderedSame;
            }
            else
            {
				if ([obj1 CGPointValue].y > [obj2 CGPointValue].y) {
					return (NSComparisonResult)NSOrderedDescending;
				}
                
				if ([obj1 CGPointValue].y < [obj2 CGPointValue].y) {
					return (NSComparisonResult)NSOrderedAscending;
				}
				return (NSComparisonResult)NSOrderedSame;
                
            }
        }];
        
		// add the array of points to the lines array, still with me?
		[lines addObject:points];
    }
    
	// save the lines array
	self.series = lines;
    
	// finaly round and save the high and low values
    if(self.roundYAxis)
    {
        self.highestYValue = [self roundValue:highestYValue Up:YES];
        self.highestXValue = [self roundValue:highestXValue Up:YES];
    }
    else
    {
        self.highestXValue = highestXValue;
        self.highestYValue = highestYValue;
    }
    
    if(self.roundXAxis)
    {
        self.lowestYValue = [self roundValue:lowestYValue Up:NO];
        self.lowestXValue = [self roundValue:lowestXValue Up:NO];
    }
    else
    {
        self.lowestXValue = lowestXValue;
        self.lowestYValue = lowestYValue;
    }
    
    [self calclateInset];
}

- (void)populateAxisLabelStrings
{
    
}

- (void)calclateInset
{
    self.axisLabelStrings = [NSMutableArray array];
    
    CGPoint inset = CGPointZero;
    
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
                numberOfLabels = floor((self.highestXValue - self.lowestXValue) / intervalOfLabels);
            }
            else if (axis == BBGraphAxisY)
            {
                numberOfLabels = floor((self.highestYValue - self.lowestYValue) / intervalOfLabels);
                
            }
        }
        else if ([self.dataSource respondsToSelector:@selector(graph:numberOfLabelsForAxis:)])
        {
            numberOfLabels = [self.dataSource graph:self numberOfLabelsForAxis:axis];
            if(axis == BBGraphAxisX)
            {
                intervalOfLabels = (self.highestXValue - self.lowestXValue) / numberOfLabels;
            }
            else if (axis == BBGraphAxisY)
            {
                intervalOfLabels = (self.highestYValue - self.lowestYValue) / numberOfLabels;
                
            }
        }
        
        //Iterate through the labels and find their associated strings
        for(int j = 0; j <= numberOfLabels; j++)
        {
            NSString *labelText;
            //Calculate the value of the label we need
            CGFloat labelValue;
            if (axis == BBGraphAxisX)
                labelValue = self.lowestXValue + j * intervalOfLabels;
            else
                labelValue = self.lowestYValue + j * intervalOfLabels;
            
            labelValue -= fmodf(labelValue, intervalOfLabels);
            
            // ask the delegate for a formated string
            if([self.delegate respondsToSelector:@selector(graph:stringForLabelAtValue:onAxis:)])
            {
                labelText = [self.delegate graph:self stringForLabelAtValue:labelValue onAxis:axis];
            }
            // or use basic formatting
            else
            {
                labelText = [NSString stringWithFormat:@"%g", labelValue];
            }
            
            //Save the label to a property to prevent calling the above delegate method more than once per label per reload
            if(j == 0)
            {
                [self.axisLabelStrings addObject:[NSMutableDictionary dictionary]];
            }
            [self.axisLabelStrings[axis] setObject:labelText forKey:@(labelValue)];
            
            //Calculate the size of the label which would be created
            CGSize size = CGSizeZero;
            UIFont *font = axis == BBGraphAxisX ? self.xAxisFont : self.yAxisFont;
            
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
            inset.x = maxLabelWidth + axisDataPointPadding + axisDataPointSize;
        }
        else
        {
            inset.y = maxLabelHeight + axisDataPointPadding + axisDataPointSize;
        }
        
        [self.numberOfAxisLabels setObject:@(numberOfLabels) forKey:@(axis)];
        [self.intervalOfAxisLabels setObject:@(intervalOfLabels) forKey:@(axis)];
    }
    
    self.graphSpaceInset = inset;
}

#pragma mark - Set Up Spaces

- (void)setUpValueSpace
{
    CGFloat xSize;
    CGFloat ySize;
    
    xSize = self.scaleXAxisToValues ? self.highestXValue - self.lowestXValue : self.highestXValue;
    ySize = self.scaleYAxisToValues ? self.highestYValue - self.lowestYValue : self.highestYValue;
    
	self.valueSpace = CGRectMake(0,
								 0,
								 xSize,
								 ySize);
}

- (void)setupGraphSpace
{
    CGRect screenSpaceFrame = self.screenSpaceView.frame;
    screenSpaceFrame.origin.x += self.graphSpaceInset.x;
    screenSpaceFrame.size.width -= self.graphSpaceInset.x;
    screenSpaceFrame.size.height -= self.graphSpaceInset.y;
    self.screenSpaceView.frame = screenSpaceFrame;
    self.axisView.frame = self.screenSpaceView.frame;
}

- (void)reloadData
{
	// Should Be subclassed
    NSAssert(NO, @"This method should be subclassed");
}

#pragma mark

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
        _screenSpaceView.clipsToBounds = NO;
		[self addSubview:_screenSpaceView];
	}
    _screenSpaceView.backgroundColor = self.graphBackgroundColor;
	return _screenSpaceView;
}

- (CGRect)screenSpace
{
	return self.screenSpaceView.bounds;
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

- (CGFloat)roundValue:(CGFloat)number Up:(BOOL)up
{
    // this dosn't work well for decimals between 0 and 1;
    
    double numberOfSignificentFigures = ceil(log10(fabs(number)));
    
    int multiple = pow(10, numberOfSignificentFigures-1);
    
    int u;
    
    if (up)
    {
        u = ceil(number/multiple);
    }
    else
    {
        u = floor(number/multiple);
    }
    
    return u * multiple;
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
