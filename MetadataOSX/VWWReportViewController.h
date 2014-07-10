//
//  VWWReportViewController.h
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/9/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import MapKit;
@class VWWReportViewController;

@protocol VWWReportViewControllerDelegate <NSObject>
-(void)reportViewController:(VWWReportViewController*)sender coordinate:(CLLocationCoordinate2D)coordinate;
@end

@interface VWWReportViewController : NSViewController
@property (weak) id <VWWReportViewControllerDelegate> delegate;
@property (strong) MKMapView *mapView;
@end
