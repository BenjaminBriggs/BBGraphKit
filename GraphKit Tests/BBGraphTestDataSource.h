//
//  BBGraphTestDataSource.h
//  GraphKit
//
//  Created by Benjamin Briggs on 26/03/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BBGraph.h"

typedef NSUInteger(^BBGraphTestNumberOfSeries)(void);
typedef NSUInteger(^BBGraphTestNumberOfPointsInSeries)(NSUInteger series);
typedef CGPoint(^BBGraphTestPointForIndexPath)(NSIndexPath *indexPath);
typedef BBGraphType(^BBGraphTestTypeForSeries)(NSUInteger series);


@interface BBGraphTestDataSource : NSObject
<BBGraphDataSource>

@property (nonatomic, copy) BBGraphTestNumberOfSeries numberOfSeries;
@property (nonatomic, copy) BBGraphTestNumberOfPointsInSeries numberOfPointsInSeries;
@property (nonatomic, copy) BBGraphTestPointForIndexPath pointForIndexPath;
@property (nonatomic, copy) BBGraphTestTypeForSeries typeForSeries;

@end