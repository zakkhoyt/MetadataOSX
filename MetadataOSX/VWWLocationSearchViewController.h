//
//  VWWLocationSearchViewController.h
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/9/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import MapKit;
@class VWWLocationSearchViewController;

@protocol VWWLocationSearchViewControllerDelegate <NSObject>
-(void)reportVWWMainViewController:(VWWLocationSearchViewController*)sender coordinate:(CLLocationCoordinate2D)coordinate;
@end

@interface VWWLocationSearchViewController : NSViewController
@property (weak) id <VWWLocationSearchViewControllerDelegate> delegate;
@property (strong) MKMapView *mapView;
@end
