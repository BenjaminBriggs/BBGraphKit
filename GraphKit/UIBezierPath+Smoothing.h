//
//  UIBezierPath+Smoothing.h
//  GraphKit
//
//  Created by Stephen Groom on 04/02/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//
// Based on code from Erica Sadun

#import <UIKit/UIKit.h>

@interface UIBezierPath (Smoothing)
- (UIBezierPath *)smoothedPathWithGranularity:(CGFloat)granularity;

#define VALUE(_INDEX_) [NSValue valueWithCGPoint:points[_INDEX_]]
#define POINT(_INDEX_) [(NSValue *)[points objectAtIndex:_INDEX_] CGPointValue]

@end
