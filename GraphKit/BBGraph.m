//
//  BBGraph.m
//  GraphKit
//
//  Created by Stephen Groom on 29/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "BBGraph.h"

@interface BBGraph ()

@property (nonatomic, strong) NSArray *series; // an array of arrays of nsvalues for cgpoints

@end

@implementation BBGraph

- (instancetype)init
{
    self = [super init];
    if (self) {
        _axisColor = [UIColor blackColor];
    }
    return self;
}

@end
