//
//  ViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/8/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "ViewController.h"
#import "SMGooglePlacesController.h"
#import "FileSystemItem.h"
#import "VWWReportViewController.h"

@import MapKit;
@import AVFoundation;
@import ImageIO;

typedef void (^VWWEmptyBlock)(void);
typedef void (^VWWCLLocationCoordinate2DBlock)(CLLocationCoordinate2D coordinate);
typedef void (^VWWBoolDictionaryBlock)(BOOL success, NSDictionary *dictionary);

@interface ViewController () <NSViewControllerPresentationAnimator, MKMapViewDelegate, VWWReportViewControllerDelegate>
@property (strong) NSMutableArray *contents;
@property (strong) NSIndexSet *selectedIndexes;
@property (unsafe_unretained) IBOutlet NSTextView *metadataTextView;
@property (weak) IBOutlet MKMapView *mapView;
@property (weak) IBOutlet NSPopUpButton *metadataPopup;
@property (weak) IBOutlet NSImageView *imageView;
@property (strong) VWWEmptyBlock completionBlock;
@property (weak) IBOutlet NSButton *writeGPSButton;
@property (weak) IBOutlet NSButton *removeGPSButton;
@property (weak) IBOutlet NSPathControl *pathControl;
@property (weak) IBOutlet NSOutlineView *outlineView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *picturesPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Pictures"];
    self.pathControl.URL = [NSURL fileURLWithPath:picturesPath];

    [self.outlineView setAction:@selector(outlineViewAction:)];
    [self.outlineView setDoubleAction:@selector(outlineViewDoubleAction:)];
    
//    [self.pathControl setDoubleAction:@selector(pathControlAction:)];
    self.pathControl.allowedTypes = @[@"public.folder"];
    

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
    
}

-(NSDictionary*)readMetadataFromURL:(NSURL*)url{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        NSLog(@"Could not read metadata for %@", url.path);
        return nil;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
                             nil];
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    NSDictionary *metadata = nil;
    if (imageProperties) {
//        NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
//        NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
//        NSLog(@"Image dimensions: %@ x %@ px", width, height);
        metadata = (__bridge NSDictionary *)(imageProperties);
        CFRelease(imageProperties);
    }
    CFRelease(imageSource);
    
    return metadata;
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier
                                  sender:(id)sender{
    return YES;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"VWWSegueMainToReport"]){
        VWWReportViewController *vc = segue.destinationController;
        vc.mapView = self.mapView;
        vc.delegate = self;
    }
}



-(void)writeMetadata:(NSDictionary*)metadata toURL:(NSURL*)url completionBlock:(VWWBoolDictionaryBlock)completionBlock{

    // Create source
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        NSLog(@"%s Could not create image source for %@", __PRETTY_FUNCTION__, url.path);
        return completionBlock(NO, nil);
    }
    
    // Create destination
//    NSURL *destURL = [NSURL URLWithString:@"file:///Users/zakkhoyt/__test.jpg"];
//    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)destURL, kUTTypeJPEG, 1, NULL);

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
    
    // TODO: read back the dictionary from the actual file
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
//        NSURL *url = [NSURL fileURLWithPath:item.fullPath];
//        NSDictionary *metadata = [self readMetadataFromURL:url];
//        //item.metadata = [metadata mutableCopy];
//        [item setMetadata:[metadata mutableCopy]];
        NSDictionary *gpsDictionary = [item.metadata valueForKeyPath:@"{GPS}"];
        if(gpsDictionary){
            __block NSString *coordinateName = nil;
            [self extractLocationFromGPSDictionary:gpsDictionary completionBlock:^(CLLocationCoordinate2D coordinate) {
                coordinateName = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
            }];
            return coordinateName;
        } else {
            return @"n/a";
        }

        return @"coordinate";
    } else if([tableColumn.identifier isEqualToString:@"location"]){
//        VWWContentItem *item = self.contents[row];
//        NSDictionary *gpsDictionary = [item.metaData valueForKeyPath:@"{GPS}"];
//        if(gpsDictionary){
//            [self extractLocationFromGPSDictionary:gpsDictionary completionBlock:^(CLLocationCoordinate2D coordinate) {
//                [SMGooglePlacesController stringLocalityFromLatitude:coordinate.latitude longitude:coordinate.longitude completionBlock:^(NSString *name) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if(name){
//                            cellView.textField.stringValue = name;
//                        } else {
//                            cellView.textField.stringValue = @"n/a";
//                        }
//                    });
//                }];
//            }];
//        } else {
//            cellView.textField.stringValue = @"n/a";
//        }
        return @"n/a";
    }
    
    return nil;
}

#pragma mark NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(FileSystemItem*)item {
    return NO;
}


#pragma mark IBActions

- (IBAction)buttonAction:(id)sender {
    [self performSegueWithIdentifier:@"VWWSegueMainToReport" sender:self];
    
}


- (IBAction)reportButtonAction:(NSButton *)sender {
//    NSWindowController *windowController = [self.storyboard instantiateControllerWithIdentifier:@"VWWReportWindowController"];
//    [[windowController window]makeKeyWindow];
    
    NSViewController *vc = [self.storyboard instantiateControllerWithIdentifier:@"VWWReportViewController"];
    [self presentViewController:vc animator:self];
}


- (IBAction)browseButtonAction:(id)sender {
//    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    openPanel.canChooseDirectories = YES;
//    openPanel.canChooseFiles = NO;
//    
//    
//    __weak ViewController *weakSelf = self;
//    [openPanel beginWithCompletionHandler:^(NSInteger result) {
//        //        NSString *dir = openPanel.directoryURL.description;
//        //        dir = [dir stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
//        //        NSURL *url = openPanel.directoryURL;
//        NSURL *url = openPanel.URLs[0];
//        NSString *path = url.path;
//        
//        [weakSelf seachForFilesInDirectory:path];
//        
//    }];
}

- (IBAction)writeButtonAction:(id)sender {
    
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
        exifDictionary[(NSString*)kCGImagePropertyExifMakerNote] = [NSString stringWithFormat:@"Modified by %@", appName];
        
        // {GPS}
        NSMutableDictionary *gpsDictionary = [@{}mutableCopy];
        [self applyCoordinate:self.mapView.centerCoordinate toGPSDictionary:gpsDictionary];
        item.metadata[(NSString*)kCGImagePropertyGPSDictionary] = gpsDictionary;
        
        [self writeMetadata:item.metadata toURL:[NSURL fileURLWithPath:item.fullPath] completionBlock:^(BOOL success, NSDictionary *dictionary) {
            if(success){
                item.metadata = [dictionary mutableCopy];
            } else {
                
            }
        }];
        
        

    }];

    FileSystemItem *testItem = [self.outlineView itemAtRow:self.selectedIndexes.firstIndex];
    NSLog(@"testItem.fullPath: %@", testItem.fullPath);
    [self.outlineView reloadDataForRowIndexes:self.selectedIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outlineView.numberOfColumns - 1)]];
}

- (IBAction)eraseGPSButtonAction:(NSButton *)sender {
    
    [self.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        FileSystemItem *item = [self.outlineView itemAtRow:index];

        if(item.metadata == nil){
            NSLog(@"TODO: erasing data from non-photo?");
            return;
        }
        
        // {GPS}
        [item.metadata removeObjectForKey:(NSString*)kCGImagePropertyGPSDictionary];
        
        [self writeMetadata:item.metadata toURL:[NSURL fileURLWithPath:item.fullPath] completionBlock:^(BOOL success, NSDictionary *dictionary) {
            if(success){
                item.metadata = [dictionary mutableCopy];
            } else {
                
            }
        }];
        
    }];
    
    [self.outlineView reloadDataForRowIndexes:self.selectedIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outlineView.numberOfColumns - 1)]];
}

- (IBAction)centerMapButtonAction:(NSButton *)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
}




#pragma mark Private methods

- (IBAction)pathControlAction:(NSPathControl *)sender {
    sender.URL = sender.clickedPathItem.URL;
    [self.outlineView reloadData];
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

- (IBAction)metadataPopupAction:(NSPopUpButton *)sender {
    NSString *key = sender.selectedItem.title;
    NSLog(@"Key: %@", key);
    
    FileSystemItem *item = [self.outlineView itemAtRow:self.selectedIndexes.firstIndex];
    NSDictionary *dictionary = item.metadata[key];
    
    if([key rangeOfString:@"{"].location == 0){
        if(dictionary){
            self.metadataTextView.string = dictionary.description;
        } else {
            self.metadataTextView.string = @"Error";
        }
    } else if([key isEqualToString:@"All"]){
        self.metadataTextView.string = item.metadata.description;
    }
}


-(void)outlineViewAction:(NSOutlineView*)sender {
    NSLog(@"%s", __FUNCTION__);
    
    NSInteger selectedRow = [self.outlineView selectedRow];
    if (selectedRow != -1) {
        self.selectedIndexes = self.outlineView.selectedRowIndexes;
        FileSystemItem *item = [self.outlineView itemAtRow:selectedRow];
        
        
//        if(item.isDirectory){
//            self.imageView.image = nil;
//            self.metadataTextView.string = @"";
//            [self.metadataPopup removeAllItems];
//            
//            self.removeGPSButton.hidden = YES;
//            self.writeGPSButton.hidden = YES;
//            self.mapView.hidden = YES;
//            self.imageView.hidden = YES;
//            
//            
//        } else {
//            self.removeGPSButton.hidden = NO;
//            self.writeGPSButton.hidden = NO;
//            self.mapView.hidden = NO;
//            self.imageView.hidden = NO;
//            
            // Image
            self.imageView.image = [[NSImage alloc]initWithContentsOfURL:[NSURL fileURLWithPath:item.fullPath]];
            
            // Text View
        if(item.metadata){
            self.metadataTextView.string = item.metadata.description;
        }
        
            // Popup
            [self.metadataPopup removeAllItems];
            [self.metadataPopup addItemWithTitle:@"All"];
            
            NSDictionary *tiffDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyTIFFDictionary];
            if(tiffDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyTIFFDictionary];
            }
            
            NSDictionary *gifDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
            if(gifDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyGIFDictionary];
            }
            
            NSDictionary *jfifDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyJFIFDictionary];
            if(jfifDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyJFIFDictionary];
            }
            
            NSDictionary *exifDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyExifDictionary];
            if(exifDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyExifDictionary];
            }
            
            NSDictionary *pngDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyPNGDictionary];
            if(pngDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyPNGDictionary];
            }
            
            NSDictionary *iptcDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyIPTCDictionary];
            if(iptcDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyIPTCDictionary];
            }
            
            NSDictionary *gpsDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyGPSDictionary];
            if(gpsDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyGPSDictionary];
            }
            
            NSDictionary *rawDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyRawDictionary];
            if(rawDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyRawDictionary];
            }
            
            NSDictionary *ciffDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyCIFFDictionary];
            if(ciffDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyCIFFDictionary];
            }
            
            NSDictionary *canonDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerCanonDictionary];
            if(canonDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerCanonDictionary];
            }
            
            NSDictionary *nikonDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerNikonDictionary];
            if(nikonDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerNikonDictionary];
            }
            
            NSDictionary *minoltaDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerMinoltaDictionary];
            if(minoltaDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerMinoltaDictionary];
            }
            
            NSDictionary *fujiDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerFujiDictionary];
            if(fujiDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerFujiDictionary];
            }
            
            NSDictionary *olumpusDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerOlympusDictionary];
            if(olumpusDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerOlympusDictionary];
            }
            
            NSDictionary *pentaxDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerPentaxDictionary];
            if(pentaxDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerPentaxDictionary];
            }
            
            NSDictionary *bim8Dictionary = [item.metadata valueForKey:(NSString*)kCGImageProperty8BIMDictionary];
            if(bim8Dictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImageProperty8BIMDictionary];
            }
            
            NSDictionary *dngDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyDNGDictionary];
            if(dngDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyDNGDictionary];
            }
            
            NSDictionary *exifAuxDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyExifAuxDictionary];
            if(exifAuxDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyExifAuxDictionary];
            }
            
            NSDictionary *openEXRDDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyOpenEXRDictionary];
            if(openEXRDDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyOpenEXRDictionary];
            }
            
            NSDictionary *appleDictionary = [item.metadata valueForKey:(NSString*)kCGImagePropertyMakerAppleDictionary];
            if(appleDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerAppleDictionary];
            }
            [self.metadataPopup selectItemAtIndex:0];
            
            // Coords
            for(id<MKAnnotation> annotation in self.mapView.annotations){
                //                if([annotation isKindOfClass:[MKUserLocation class]] == NO){
                [self.mapView removeAnnotation:annotation];
                //                }
            }
            
            [self.mapView removeAnnotations:self.mapView.annotations];
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
                [self.mapView setRegion:MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.5, 0.5)) animated:YES];
                
                
                [item setAnnotationCoordinate:coordinate];
                [self.mapView addAnnotation:item];
                
                
            }
//        }
    }
}

-(void)outlineViewDoubleAction:(NSOutlineView*)sender{
    NSLog(@"%s", __FUNCTION__);
}





#pragma mark Implements NSTableViewDelegate


#pragma mark Animation wrappers
+ (void)animateWithDuration:(NSTimeInterval)duration
                  animation:(void (^)(void))animationBlock
                 completion:(void (^)(void))completionBlock
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:duration];
    animationBlock();
    [NSAnimationContext endGrouping];
    
    if(completionBlock)
    {
        VWWEmptyBlock completionBlockCopy = [completionBlock copy];
        [self performSelector:@selector(runEndBlock:) withObject:completionBlockCopy afterDelay:duration];
    }
}

+ (void)runEndBlock:(void (^)(void))completionBlock
{
    completionBlock();
}

#pragma mark NSViewControllerPresentationAnimator

- (void)animatePresentationOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController{
    viewController.view.frame = fromViewController.view.frame;
    viewController.view.alphaValue = 1.0;
    viewController.view.alphaValue = 0.0;
}

- (void)animateDismissalOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController{
    
}


#pragma mark MKMapDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    NSLog(@"annotation.class: %@", [annotation class]);
//    if(annotation isKindOfClass:<#(__unsafe_unretained Class)#>
    return nil;
}



#pragma mark VWWReportViewControllerDelegate
-(void)reportViewController:(VWWReportViewController*)sender coordinate:(CLLocationCoordinate2D)coordinate{
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.05, 0.05));
    [self.mapView setRegion:region animated:YES];
}


@end
