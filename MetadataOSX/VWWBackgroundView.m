//
//  VWWBackgroundView.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/9/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWBackgroundView.h"

@implementation VWWBackgroundView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [NSColor blackColor];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Fill in background Color
    CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];

    
    NSColor *color = [self.backgroundColor colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    CGFloat red = color.redComponent;
    CGFloat green = color.greenComponent;
    CGFloat blue  = color.blueComponent;
    
    
    CGContextSetRGBFillColor(context, red, green, blue, 1.0);
    CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}


@end
