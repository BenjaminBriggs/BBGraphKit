//
//  UILabel+BBGraphKit.m
//  GraphKit
//
//  Created by Stephen Groom on 29/01/2014.
//  Copyright (c) 2014 Benjamin Briggs. All rights reserved.
//

#import "UILabel+BBGraphKit.h"

@implementation UILabel (BBGraphKit)
- (void) sizeLabelToRect: (CGRect) labelRect  {
    
    // Set the frame of the label to the targeted rectangle
    self.frame = labelRect;
    
    // Try all font sizes from largest to smallest font size
    int fontSize = 300;
    int minFontSize = 5;
    
    // Fit label width wize
    CGSize constraintSize = CGSizeMake(self.frame.size.width, MAXFLOAT);
    
    do {
        // Set current font size
        self.font = [UIFont boldSystemFontOfSize:fontSize];
        
        // Find label size for current font size
        CGSize labelSize;
        // iOS 7+
        if ([self.text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
        {
            labelSize = [self.text boundingRectWithSize:constraintSize
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:@{NSFontAttributeName:self.font}
                                           context:nil].size;
        }
        // iOS < 7
        else
        {
            labelSize = [self.text sizeWithFont:self.font
                         constrainedToSize:constraintSize
                             lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        // Done, if created label is within target size
        if( labelSize.height <= self.frame.size.height )
            break;
        
        // Decrease the font size and try again
        fontSize -= 2;
        
    } while (fontSize > minFontSize);
}
@end
