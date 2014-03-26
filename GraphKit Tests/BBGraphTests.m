//
//  BBGraphTests.m
//  GraphKit
//
//  Created by Benjamin Briggs on 26/03/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BBGraph.h"
#import "BBGraphTestDataSource.h"

@interface BBGraphTests : XCTestCase

@property (nonatomic, strong) BBGraph *graph;
@property (nonatomic, strong) BBGraphTestDataSource *graphDataSource;

@end

@implementation BBGraphTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	self.graph = [[BBGraph alloc] init];
	self.graphDataSource = [[BBGraphTestDataSource alloc] init];
	self.graph.dataSource = self.graphDataSource;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInserts
{
	[self.graphDataSource setNumberOfSeries:^NSUInteger(void){
		return 3;
	}];
	[self.graphDataSource setNumberOfPointsInSeries:^NSUInteger(NSUInteger series){
		return 3;
	}];
	[self.graphDataSource setPointForIndexPath:^CGPoint(NSIndexPath *indexPath){
		return CGPointMake(10, 10);
	}];
	[self.graphDataSource setTypeForSeries:^BBGraphType(NSUInteger series){
		return BBGraphTypeLine;
	}];

	[self.graph reloadData];

	///

	[self.graphDataSource setNumberOfSeries:^NSUInteger(void){
		return 4;
	}];

	[self.graphDataSource setPointForIndexPath:^CGPoint(NSIndexPath *indexPath){
		return CGPointMake(100, 100);
	}];

	XCTAssertNoThrow([self.graph insertSeries:[NSIndexSet indexSetWithIndex:2]], @"");

	XCTAssertEqual(self.graph.numberOfSeries, 4, @"The number of series in the graph is not what it should be after a insert");
	XCTAssertEqual([self.graph pointAtIndexPath:[NSIndexPath indexPathForPoint:0 inSeries:2]].x, 100, @"New series was inserted in the wrong location");
	XCTAssertEqual([self.graph pointAtIndexPath:[NSIndexPath indexPathForPoint:0 inSeries:0]].x, 10, @"New series changed values out side it's scope");

	XCTAssertThrowsSpecificNamed([self.graph insertSeries:[NSIndexSet indexSetWithIndex:4]], NSException, NSInternalInconsistencyException, @"");

	[self.graphDataSource setNumberOfSeries:^NSUInteger(void){
		return 5;
	}];

	XCTAssertThrowsSpecificNamed([self.graph insertSeries:[NSIndexSet indexSetWithIndex:29]], NSException, NSRangeException, @"");
}

- (void)testDeletes
{
	[self.graphDataSource setNumberOfSeries:^NSUInteger(void){
		return 3;
	}];
	[self.graphDataSource setNumberOfPointsInSeries:^NSUInteger(NSUInteger series){
		return 3;
	}];
	[self.graphDataSource setPointForIndexPath:^CGPoint(NSIndexPath *indexPath){
		return CGPointMake(10, 10);
	}];
	[self.graphDataSource setTypeForSeries:^BBGraphType(NSUInteger series){
		return BBGraphTypeLine;
	}];

	[self.graph reloadData];

	///

	[self.graphDataSource setNumberOfSeries:^NSUInteger(void){
		return 2;
	}];

	XCTAssertNoThrow([self.graph deleteSeries:[NSIndexSet indexSetWithIndex:2]], @"");

	XCTAssertEqual(self.graph.numberOfSeries, 2, @"The number of series in the graph is not what it should be after a insert");

	XCTAssertThrowsSpecificNamed([self.graph deleteSeries:[NSIndexSet indexSetWithIndex:4]], NSException, NSInternalInconsistencyException, @"");

	[self.graphDataSource setNumberOfSeries:^NSUInteger(void){
		return 1;
	}];

	XCTAssertThrowsSpecificNamed([self.graph deleteSeries:[NSIndexSet indexSetWithIndex:29]], NSException, NSRangeException, @"");
}

@end
