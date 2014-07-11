//
//  VWWMainViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/8/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWMainViewController.h"
#import "VWWPlacesController.h"
#import "FileSystemItem.h"
#import "VWWLocationSearchViewController.h"
#import "VWWMetadataViewController.h"
#import "VWWBackgroundView.h"
@import MapKit;
@import AVFoundation;
@import ImageIO;

typedef void (^VWWEmptyBlock)(void);
typedef void (^VWWCLLocationCoordinate2DBlock)(CLLocationCoordinate2D coordinate);
typedef void (^VWWBoolDictionaryBlock)(BOOL success, NSDictionary *dictionary);

static NSString *VWWSegueMainToMetadata = @"VWWSegueMainToMetadata";
static NSString *VWWMainViewControllerInitialDirKey = @"initialDir";
static NSString *VWWSegueMainToMetadataReport = @"VWWSegueMainToMetadataReport";


@interface VWWMainViewController () <MKMapViewDelegate, VWWLocationSearchViewControllerDelegate>
@property (strong) NSMutableArray *contents;
@property (strong) NSIndexSet *selectedIndexes;
@property (weak) IBOutlet MKMapView *mapView;
@property (weak) IBOutlet NSImageView *imageView;
@property (strong) VWWEmptyBlock completionBlock;

@property (weak) IBOutlet NSButton *writeGPSButton;
@property (weak) IBOutlet NSButton *writeDateButton;
@property (weak) IBOutlet NSButton *writeGPSDateButton;
@property (weak) IBOutlet NSButton *eraseGPSButton;
@property (weak) IBOutlet NSButton *eraseDateButton;
@property (weak) IBOutlet NSButton *eraseGPSDateButton;




@property (weak) IBOutlet NSPathControl *pathControl;
@property (weak) IBOutlet NSOutlineView *outlineView;
@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet VWWBackgroundView *imageBackgroundView;

@end

@implementation VWWMainViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *initialDir = [[NSUserDefaults standardUserDefaults] objectForKey:VWWMainViewControllerInitialDirKey];
    if(initialDir == nil){
        initialDir = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Pictures"];
    }
    
    self.pathControl.URL = [NSURL fileURLWithPath:initialDir];
    
    [self.outlineView setAction:@selector(outlineViewAction:)];
    [self.outlineView setDoubleAction:@selector(outlineViewDoubleAction:)];
    
    self.pathControl.allowedTypes = @[@"public.folder"];
    
    self.datePicker.dateValue = [NSDate date];
    self.imageBackgroundView.backgroundColor = [NSColor darkGrayColor];
}


-(void)viewWillAppear{
    NSString *initialDir = [[NSUserDefaults standardUserDefaults] objectForKey:VWWMainViewControllerInitialDirKey];
    if(initialDir == nil){
        initialDir = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Pictures"];
    }

    self.view.window.title = initialDir;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    return YES;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"VWWSegueMainToReport"]){
        VWWLocationSearchViewController *vc = segue.destinationController;
        vc.mapView = self.mapView;
        vc.delegate = self;
    } else if([segue.identifier isEqualToString:VWWSegueMainToMetadata]){
        VWWMetadataViewController *vc = segue.destinationController;
        vc.item = sender;
    }
}

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(FileSystemItem*)item {
    return (item == nil) ? 1 : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(FileSystemItem*)item {
    
    if(item == nil){
        return YES;
    } else {
        // We will load the
        NSURL *url = [NSURL fileURLWithPath:item.fullPath];
        NSDictionary *metadata = [self readMetadataFromURL:url];
        [item setMetadata:[metadata mutableCopy]];
        return ([item numberOfChildren] != -1);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(FileSystemItem*)item {
    return (item == nil) ? [FileSystemItem rootItemWithPath:self.pathControl.URL.path] : [(FileSystemItem *)item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(FileSystemItem*)item {
    if([tableColumn.identifier isEqualToString:@"tree"]){
        return (item == nil) ? @"/" : (id)[item relativePath];
    } else if([tableColumn.identifier isEqualToString:@"coordinate"]){
        NSDictionary *gpsDictionary = [item.metadata valueForKeyPath:@"{GPS}"];
        if(gpsDictionary){
            __block NSString *coordinateName = nil;
            [self extractLocationFromGPSDictionary:gpsDictionary completionBlock:^(CLLocationCoordinate2D coordinate) {
                if(coordinate.latitude == 0 && coordinate.longitude == 0){
                    coordinateName = @"n/a";
                } else {
                    coordinateName = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
                }
            }];
            return coordinateName;
        } else {
            return @"n/a";
        }
        
        return @"coordinate";
    } else if([tableColumn.identifier isEqualToString:@"location"]){
//        NSDictionary *gpsDictionary = [item.metadata valueForKeyPath:@"{GPS}"];
//        if(gpsDictionary){
//             __block NSString *locationName = nil;
//            [self extractLocationFromGPSDictionary:gpsDictionary completionBlock:^(CLLocationCoordinate2D coordinate) {
//                [VWWPlacesController stringLocalityFromLatitude:coordinate.latitude longitude:coordinate.longitude completionBlock:^(NSString *name) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if(name){
//                            locationName = name;
//                        } else {
//                            locationName = @"n/a";
//                        }
//                    });
//                }];
//            }];
//            return locationName;
//        }
        return @"n/a";
    } else if([tableColumn.identifier isEqualToString:@"date"]){
        NSDictionary *exifDictionary = [item.metadata valueForKeyPath:(NSString*)kCGImagePropertyExifDictionary];
        if(exifDictionary){
            NSString *dateName = exifDictionary[(NSString*)kCGImagePropertyExifDateTimeOriginal];
            if(dateName && [dateName isEqualToString:@""] == NO){
                return dateName;
            } else {
                return @"n/a";
            }
        } else {
            return @"n/a";
        }
        
        return @"coordinate";
        
    }
    
    return nil;
}

#pragma mark NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(FileSystemItem*)item {
    return NO;
}

#pragma mark IBActions

- (IBAction)reportButtonAction:(id)sender {
    [self performSegueWithIdentifier:VWWSegueMainToMetadataReport sender:self];
}


- (IBAction)buttonAction:(id)sender {
    [self performSegueWithIdentifier:@"VWWSegueMainToReport" sender:self];
    
}

-(NSString*)stringFromDate:(NSDate*)date{
    // Convert date to string (exif format)
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy:MM:dd hh:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:date];
    return dateString;
}

- (IBAction)writeGPSButtonAction:(id)sender {
    [self writeMetatdataGPS:YES date:NO];
}
- (IBAction)writeDateButtonAction:(id)sender {
    [self writeMetatdataGPS:NO date:YES];
}
- (IBAction)writeDateAndGPSButtonAction:(id)sender {
    [self writeMetatdataGPS:YES date:YES];
}

- (IBAction)eraseGPSButtonAction:(id)sender {
    [self eraseMetatdataGPS:YES date:NO];
}
- (IBAction)eraseDateButtonAction:(id)sender {
    [self eraseMetatdataGPS:NO date:YES];
}
- (IBAction)eraseDateAndGPSButtonAction:(id)sender {
    [self eraseMetatdataGPS:YES date:YES];
}

- (IBAction)centerMapButtonAction:(NSButton *)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
}

- (IBAction)pathControlAction:(NSPathControl *)sender {
    sender.URL = sender.clickedPathItem.URL;
    [self.outlineView reloadData];
    
    [[NSUserDefaults standardUserDefaults] setObject:sender.URL.path forKey:VWWMainViewControllerInitialDirKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(void)outlineViewAction:(NSOutlineView*)sender {
    
    
    NSInteger selectedRow = [self.outlineView selectedRow];
    if (selectedRow != -1) {
        self.selectedIndexes = self.outlineView.selectedRowIndexes;
        FileSystemItem *item = [self.outlineView itemAtRow:selectedRow];
        
        if(item.metadata){
            self.writeGPSButton.hidden = NO;
            self.writeDateButton.hidden = NO;
            self.writeGPSDateButton.hidden = NO;
            self.eraseGPSButton.hidden = NO;
            self.eraseDateButton.hidden = NO;
            self.eraseGPSDateButton.hidden = NO;
        } else {
            self.writeGPSButton.hidden = YES;
            self.writeDateButton.hidden = YES;
            self.writeGPSDateButton.hidden = YES;
            self.eraseGPSButton.hidden = YES;
            self.eraseDateButton.hidden = YES;
            self.eraseGPSDateButton.hidden = YES;

        }

        // Image
        self.imageView.image = [[NSImage alloc]initWithContentsOfURL:[NSURL fileURLWithPath:item.fullPath]];
        
        // Coords
        for(id<MKAnnotation> annotation in self.mapView.annotations){
            [self.mapView removeAnnotation:annotation];
        }
        
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        NSDictionary *gpsDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyGPSDictionary];
        if(gpsDictionary){
            NSNumber *latitude = [gpsDictionary valueForKeyPath:@"Latitude"];
            NSNumber *longitude = [gpsDictionary valueForKeyPath:@"Longitude"];
            NSString *latitudeRef = [gpsDictionary valueForKeyPath:@"LatitudeRef"];
            NSString *longitudeRef = [gpsDictionary valueForKeyPath:@"LongitudeRef"];
            
            float lat = 0, lon = 0;
            if([latitudeRef isEqualToString:@"S"]){
                //                latitudeString = [NSString stringWithFormat:@"-%f", latitude.floatValue];
                lat = -1 * latitude.floatValue;
            } else {
                lat = latitude.floatValue;
            }
            
            if([longitudeRef isEqualToString:@"W"]){
                lon = -1 * longitude.floatValue;
            } else {
                lon = longitude.floatValue;
            }
            
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lon);
            //                [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(lat, lon) animated:YES];
            [self.mapView setRegion:MKCoordinateRegionMake(coordinate, self.mapView.region.span) animated:YES];
            
            
            [item setAnnotationCoordinate:coordinate];
            [self.mapView addAnnotation:item];
            
            
        }
    }
}

-(void)outlineViewDoubleAction:(NSOutlineView*)sender{
    
    NSUInteger index = sender.selectedRow;
    FileSystemItem *item = [sender itemAtRow:index];
    if(item.metadata){
        [self performSegueWithIdentifier:VWWSegueMainToMetadata sender:item];
    }
}



#pragma mark Private methods



-(void)writeMetadata:(NSDictionary*)metadata toURL:(NSURL*)url completionBlock:(VWWBoolDictionaryBlock)completionBlock{
    
    // Create source
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        NSLog(@"%s Could not create image source for %@", __PRETTY_FUNCTION__, url.path);
        return completionBlock(NO, nil);
    }
    
    // Create destination
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypeJPEG, 1, NULL);
    if(imageDestination == NULL){
        NSLog(@"%s Could not create image destination for %@", __PRETTY_FUNCTION__, url.path);
        return completionBlock(NO, nil);
    }
    
    // Configure destination and set properties
    CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)(metadata));
    CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, (__bridge CFDictionaryRef)(metadata));
    
    // Write the file to disk
    bool success = CGImageDestinationFinalize(imageDestination);
    
    // Clean up
    CFRelease(imageSource);
    CFRelease(imageDestination);
    
    if(!success){
        NSLog(@"%s Failed to create new image for %@", __PRETTY_FUNCTION__, url.path);
    } else {
        NSLog(@"%s Success", __PRETTY_FUNCTION__);
    }
    
    // TODO: read back the dictionary from the actual file not just return what was passed in
    return completionBlock(success, metadata);
}


-(void)extractLocationFromGPSDictionary:(NSDictionary*)gpsDictionary completionBlock:(VWWCLLocationCoordinate2DBlock)completionBlock{
    if(gpsDictionary){
        NSNumber *latitude = [gpsDictionary valueForKeyPath:@"Latitude"];
        NSNumber *longitude = [gpsDictionary valueForKeyPath:@"Longitude"];
        NSString *latitudeRef = [gpsDictionary valueForKeyPath:@"LatitudeRef"];
        NSString *longitudeRef = [gpsDictionary valueForKeyPath:@"LongitudeRef"];
        NSString *latitudeString = nil;
        if([latitudeRef isEqualToString:@"S"]){
            latitudeString = [NSString stringWithFormat:@"-%f", latitude.floatValue];
        } else {
            latitudeString = [NSString stringWithFormat:@"%f", latitude.floatValue];
        }
        NSString *longitudeString = nil;
        if([longitudeRef isEqualToString:@"W"]){
            longitudeString = [NSString stringWithFormat:@"-%f", longitude.floatValue];
        } else {
            longitudeString = [NSString stringWithFormat:@"%f", longitude.floatValue];
        }
        
        return completionBlock(CLLocationCoordinate2DMake(latitudeString.floatValue, longitudeString.floatValue));
    }
    return completionBlock(CLLocationCoordinate2DMake(0, 0));
}

-(void)applyCoordinate:(CLLocationCoordinate2D)coordinate toGPSDictionary:(NSMutableDictionary*)gpsDictionary{
    if(coordinate.latitude == 0 && coordinate.longitude == 0) return;
    
    NSNumber *latitudeNumber = nil;
    NSString *latitudeRefString = nil;
    if(coordinate.latitude < 0){
        latitudeNumber = @(-coordinate.latitude);
        latitudeRefString = @"S";
    } else {
        latitudeNumber = @(coordinate.latitude);
        latitudeRefString = @"N";
    }
    
    NSNumber *longitudeNumber = nil;
    NSString *longitudeRefString = nil;
    if(coordinate.longitude < 0){
        longitudeNumber = @(-coordinate.longitude);
        longitudeRefString = @"W";
    } else {
        longitudeNumber = @(coordinate.longitude);
        longitudeRefString = @"E";
    }
    
    
    gpsDictionary[(NSString*)kCGImagePropertyGPSLatitude] = latitudeNumber;
    gpsDictionary[(NSString*)kCGImagePropertyGPSLatitudeRef] = latitudeRefString;
    gpsDictionary[(NSString*)kCGImagePropertyGPSLongitude] = longitudeNumber;
    gpsDictionary[(NSString*)kCGImagePropertyGPSLongitudeRef] = longitudeRefString;
}





-(NSDictionary*)readMetadataFromURL:(NSURL*)url{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        NSLog(@"Could not read metadata for %@", url.path);
        return nil;
    }
    
    NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache : [NSNumber numberWithBool:NO]};
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    NSDictionary *metadata = nil;
    if (imageProperties) {
        metadata = (__bridge NSDictionary *)(imageProperties);
        CFRelease(imageProperties);
    }
    CFRelease(imageSource);
    return metadata;
}

-(void)writeMetatdataGPS:(BOOL)gps date:(BOOL)date{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
            FileSystemItem *item = [self.outlineView itemAtRow:index];
            
            if(item.metadata == nil){
                NSLog(@"TODO: Support for writing metadata where there once was none");
                return;
            }
            
            // {Exif}
            NSProcessInfo *pi = [NSProcessInfo processInfo];
            NSString *appName = [pi processName];
            NSMutableDictionary *exifDictionary = item.metadata[(NSString*)kCGImagePropertyExifDictionary];
            if(exifDictionary == nil){
                exifDictionary = [@{}mutableCopy];
            }
            exifDictionary[(NSString*)kCGImagePropertyExifMakerNote] = [NSString stringWithFormat:@"Modified by %@", appName];
            if(date){
                NSString *dateString = [self stringFromDate:self.datePicker.dateValue];
                exifDictionary[(NSString*)kCGImagePropertyExifDateTimeOriginal] = dateString;
                exifDictionary[(NSString*)kCGImagePropertyExifDateTimeDigitized] = dateString;
                item.metadata[(NSString*)kCGImagePropertyExifDictionary] = exifDictionary;
            }
            
            if(gps){
                // {GPS}
                NSMutableDictionary *gpsDictionary = [@{}mutableCopy];
                [self applyCoordinate:self.mapView.centerCoordinate toGPSDictionary:gpsDictionary];
                item.metadata[(NSString*)kCGImagePropertyGPSDictionary] = gpsDictionary;
            }
            [self writeMetadata:item.metadata toURL:[NSURL fileURLWithPath:item.fullPath] completionBlock:^(BOOL success, NSDictionary *dictionary) {
                if(success){
                    item.metadata = [dictionary mutableCopy];
                } else {
                    
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outlineView.numberOfColumns)]];
                });

            }];
        }];
    });
}
                       

-(void)eraseMetatdataGPS:(BOOL)gps date:(BOOL)date{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
            FileSystemItem *item = [self.outlineView itemAtRow:index];
            
            if(item.metadata == nil){
                NSLog(@"TODO: erasing data from non-photo?");
                return;
            }
            
            // {GPS}
            if(gps) {
                // {GPS}
                // For what ever reason, removing keys doesn't stick, so we'll set them to nil
                //[item.metadata removeObjectForKey:(NSString*)kCGImagePropertyGPSDictionary];
                NSMutableDictionary *gpsDictionary = [@{}mutableCopy];
                gpsDictionary[(NSString*)kCGImagePropertyGPSLatitude] = @"";
                gpsDictionary[(NSString*)kCGImagePropertyGPSLatitudeRef] = @"";
                gpsDictionary[(NSString*)kCGImagePropertyGPSLongitude] = @"";
                gpsDictionary[(NSString*)kCGImagePropertyGPSLongitudeRef] = @"";
                item.metadata[(NSString*)kCGImagePropertyGPSDictionary] = gpsDictionary;
            }
            
            // {Exif}
            if(date){
                // For what ever reason, removing keys doesn't stick, so we'll set them to nil
                //            [exifDictionary removeObjectForKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
                //            [exifDictionary removeObjectForKey:(NSString*)kCGImagePropertyExifDateTimeDigitized];
                NSMutableDictionary *exifDictionary = item.metadata[(NSString*)kCGImagePropertyExifDictionary];
                exifDictionary[(NSString*)kCGImagePropertyExifDateTimeOriginal] = @"";
                exifDictionary[(NSString*)kCGImagePropertyExifDateTimeDigitized] = @"";
                item.metadata[(NSString*)kCGImagePropertyExifDictionary] = exifDictionary;
            }
            
            [self writeMetadata:item.metadata toURL:[NSURL fileURLWithPath:item.fullPath] completionBlock:^(BOOL success, NSDictionary *dictionary) {
                if(success){
                    item.metadata = [dictionary mutableCopy];
                } else {
                    
                }
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outlineView.numberOfColumns)]];
            });

            
        }];
    });
}










#pragma mark MKMapDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    NSLog(@"annotation.class: %@", [annotation class]);
    //    if(annotation isKindOfClass:<#(__unsafe_unretained Class)#>
    return nil;
}



#pragma mark VWWLocationSearchViewControllerDelegate
-(void)reportVWWMainViewController:(VWWLocationSearchViewController*)sender coordinate:(CLLocationCoordinate2D)coordinate{
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.05, 0.05));
    [self.mapView setRegion:region animated:YES];
}


@end
