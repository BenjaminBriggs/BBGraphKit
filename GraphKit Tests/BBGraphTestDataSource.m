//
//  BBGraphTestDataSource.m
//  GraphKit
//
//  Created by Benjamin Briggs on 26/03/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraphTestDataSource.h"

@implementation BBGraphTestDataSource

- (NSUInteger)numberOfSeriesInGraph:(BBGraph *)lineGraph
{
	return self.numberOfSeries();
}

- (NSUInteger)graph:(BBGraph *)lineGraph numberOfPointsInSeries:(NSInteger)series
{
	return self.numberOfPointsInSeries(series);
}

- (CGPoint)graph:(BBGraph *)lineGraph valueForPointAtIndex:(NSIndexPath *)indexPath
{
	return self.pointForIndexPath(indexPath);
}

- (BBGraphType)graph:(BBGraph *)lineGraph typeOfGraphForSeries:(NSInteger)series
{
	return self.typeForSeries(series);
}

@end