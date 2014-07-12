//
//  VWWExifViewController.h
//  Throwback
//
//  Created by Zakk Hoyt on 7/12/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class FileSystemItem;

@interface VWWExifViewController : NSViewController
@property (strong) FileSystemItem *item;
@end
