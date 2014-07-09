//
//  ViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/8/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "ViewController.h"
#import "VWWContentItem.h"
#import "SMGooglePlacesController.h"
@import MapKit;
@import AVFoundation;
@import ImageIO;

typedef void (^VWWEmptyBlock)(void);
typedef void (^VWWCLLocationCoordinate2DBlock)(CLLocationCoordinate2D coordinate);
typedef void (^VWWBoolDictionaryBlock)(BOOL success, NSDictionary *dictionary);

@interface ViewController () <NSViewControllerPresentationAnimator, MKMapViewDelegate>
@property (strong) NSMutableArray *contents;
//@property NSUInteger selectedIndex;
@property (strong) NSIndexSet *selectedIndexes;
@property (weak) IBOutlet NSTextField *pathLabel;

@property (weak) IBOutlet NSTableView *tableView;
@property (unsafe_unretained) IBOutlet NSTextView *metadataTextView;
@property (weak) IBOutlet MKMapView *mapView;
@property (weak) IBOutlet NSSegmentedControl *metadataSegment;
@property (weak) IBOutlet NSPopUpButton *metadataPopup;
@property (weak) IBOutlet NSImageView *imageView;
@property (strong) VWWEmptyBlock completionBlock;
@property (weak) IBOutlet NSButton *writeGPSButton;
@property (weak) IBOutlet NSButton *removeGPSButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *picturesDirectory = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Pictures"];
    [self seachForFilesInDirectory:picturesDirectory];
    
    [self.tableView setDoubleAction:@selector(tableViewDoubleAction:)];
    [self.tableView setAction:@selector(tableViewAction:)];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
    
}




-(void)seachForFilesInDirectory:(NSString*)path{
    
    self.contents = [@[]mutableCopy];
    self.pathLabel.stringValue = path;
    [self getDirectoryAtPath:path completion:^{
        [self.tableView reloadData];
    }];
    
}


-(void)getDirectoryAtPath:(NSString*)path completion:(VWWEmptyBlock)completion{
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableArray *contents = [[fileManager contentsOfDirectoryAtPath:path error:&error]mutableCopy];
        
        NSAssert(contents, @"error getting contents");
        
        // Add ".." to the list
        if([path isEqualToString:@"/"] == NO){
            VWWContentItem *parentDirectory = [VWWContentItem new];
            parentDirectory.path = [path stringByDeletingLastPathComponent];
            parentDirectory.displayName = @"..";
            parentDirectory.isDirectory = YES;
            parentDirectory.url = [NSURL fileURLWithPath:parentDirectory.path];
            [self.contents insertObject:parentDirectory atIndex:0];
        }
        
        for(NSInteger index = 0; index < contents.count; index++){
            NSString *contentDetailsPath = [NSString stringWithFormat:@"%@/%@", path, contents[index]];
            contentDetailsPath = [contentDetailsPath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
            
            NSDictionary *contentsAttributes = [fileManager attributesOfItemAtPath:contentDetailsPath error:&error];
            
            NSAssert(contents, @"error getting contents");
            
            BOOL isValidType = NO;
            
            // If is valid photo type
            if([contentsAttributes[NSFileType] isEqualToString:NSFileTypeRegular]){
                if([[contentDetailsPath pathExtension] compare:@"jpg" options:NSCaseInsensitiveSearch] == NSOrderedSame ||
                   [[contentDetailsPath pathExtension] compare:@"jpeg" options:NSCaseInsensitiveSearch] == NSOrderedSame |
                   [[contentDetailsPath pathExtension] compare:@"bmp" options:NSCaseInsensitiveSearch] == NSOrderedSame ||
                   [[contentDetailsPath pathExtension] compare:@"png" options:NSCaseInsensitiveSearch] == NSOrderedSame){
                    isValidType = YES;
                }
            }
            // If is directory
            else if([contentsAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]){
                isValidType = YES;
            }
            
            if(isValidType == YES){
                VWWContentItem *item = [VWWContentItem new];
                item.isDirectory = contentsAttributes[NSFileType] == NSFileTypeDirectory ? YES : NO;
                item.url = [NSURL fileURLWithPath:contentDetailsPath isDirectory:item.isDirectory];
                item.path = contentDetailsPath;
                item.displayName = [contentDetailsPath lastPathComponent];
                item.extension = [contentDetailsPath pathExtension];
                item.metaData = [[self readMetadataFromURL:item.url] mutableCopy];
                [self.contents addObject:item];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
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
        NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
        NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
        NSLog(@"Image dimensions: %@ x %@ px", width, height);
        metadata = (__bridge NSDictionary *)(imageProperties);
        CFRelease(imageProperties);
    }
    CFRelease(imageSource);
    
    return metadata;
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
    }
    NSLog(@"%s Success", __PRETTY_FUNCTION__);
    
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

#pragma mark Implements NSTableViewDataSource
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if([tableColumn.identifier isEqualToString:@"type"]){
        VWWContentItem *item = self.contents[row];
        cellView.textField.stringValue = item.isDirectory ? @"Dir" : @"File";
//        if(item.isDirectory){
//            cellView.imageView.image = [NSImage imageNamed:@"folder.png"];
//        }
//        else{
//            cellView.imageView.image = [NSImage imageNamed:@"photo.png"];
//        }

    } else if([tableColumn.identifier isEqualToString:@"titleColumn"]) {
        VWWContentItem *item = self.contents[row];
        if(item.isDirectory){
            cellView.imageView.image = [NSImage imageNamed:@"folder.png"];
        }
        else{
            cellView.imageView.image = [NSImage imageNamed:@"photo.png"];
        }
        cellView.textField.stringValue = item.displayName;
        
        return cellView;
    } else if([tableColumn.identifier isEqualToString:@"coordinates"]){
        VWWContentItem *item = self.contents[row];
        NSDictionary *gpsDictionary = [item.metaData valueForKeyPath:@"{GPS}"];
        if(gpsDictionary){
            [self extractLocationFromGPSDictionary:gpsDictionary completionBlock:^(CLLocationCoordinate2D coordinate) {
                cellView.textField.stringValue = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
            }];
        } else {
            cellView.textField.stringValue = @"n/a";
        }
    } else if([tableColumn.identifier isEqualToString:@"location"]){
        VWWContentItem *item = self.contents[row];
        NSDictionary *gpsDictionary = [item.metaData valueForKeyPath:@"{GPS}"];
        if(gpsDictionary){
            [self extractLocationFromGPSDictionary:gpsDictionary completionBlock:^(CLLocationCoordinate2D coordinate) {
//                [SMGooglePlacesController queryGooglePlacesWithLatitude:coordinate.latitude longitude:coordinate.longitude radius:10 completion:^(NSArray *places) {
//                    NSLog(@"Places: %@", places);
//                    if(places.count){
//                        NSDictionary *place = places[0];
//                        NSString *name = [place valueForKeyPath:@"name"];
//                        cellView.textField.stringValue = name;
//                    } else {
//                        cellView.textField.stringValue = @"n/a";
//                    }
//                    //cellView.textField.stringValue = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
//                }];
                [SMGooglePlacesController stringLocalityFromLatitude:coordinate.latitude longitude:coordinate.longitude completionBlock:^(NSString *name) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(name){
                            cellView.textField.stringValue = name;
                        } else {
                            cellView.textField.stringValue = @"n/a";
                        }
                    });
                }];
            }];
        } else {
            cellView.textField.stringValue = @"n/a";
        }
        
    } else {
        cellView.textField.stringValue = @"";
    }
    return cellView;
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.contents.count;
}

// Catch keyboard
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    NSLog(@"%s", __FUNCTION__);
    
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow != -1) {
        // Self
//        NSUInteger index = self.selectedIndexes.firstIndex;
        self.selectedIndexes = self.tableView.selectedRowIndexes;
        VWWContentItem  *item = self.contents[self.selectedIndexes.firstIndex];
        
        
        if(item.isDirectory){
            self.imageView.image = nil;
            self.metadataTextView.string = @"";
            [self.metadataPopup removeAllItems];

            self.removeGPSButton.hidden = YES;
            self.writeGPSButton.hidden = YES;
            self.mapView.hidden = YES;
            self.imageView.hidden = YES;
            

        } else {
            self.removeGPSButton.hidden = NO;
            self.writeGPSButton.hidden = NO;
            self.mapView.hidden = NO;
            self.imageView.hidden = NO;
            
            // Image
            self.imageView.image = [[NSImage alloc]initWithContentsOfURL:item.url];
            
            // Text View
            self.metadataTextView.string = item.metaData.description;
            
            // Popup
            [self.metadataPopup removeAllItems];
            [self.metadataPopup addItemWithTitle:@"All"];
            
            NSDictionary *tiffDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyTIFFDictionary];
            if(tiffDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyTIFFDictionary];
            }
            
            NSDictionary *gifDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
            if(gifDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyGIFDictionary];
            }
            
            NSDictionary *jfifDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyJFIFDictionary];
            if(jfifDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyJFIFDictionary];
            }
            
            NSDictionary *exifDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyExifDictionary];
            if(exifDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyExifDictionary];
            }
            
            NSDictionary *pngDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyPNGDictionary];
            if(pngDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyPNGDictionary];
            }
            
            NSDictionary *iptcDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyIPTCDictionary];
            if(iptcDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyIPTCDictionary];
            }
            
            NSDictionary *gpsDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyGPSDictionary];
            if(gpsDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyGPSDictionary];
            }
            
            NSDictionary *rawDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyRawDictionary];
            if(rawDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyRawDictionary];
            }
            
            NSDictionary *ciffDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyCIFFDictionary];
            if(ciffDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyCIFFDictionary];
            }
            
            NSDictionary *canonDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerCanonDictionary];
            if(canonDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerCanonDictionary];
            }
            
            NSDictionary *nikonDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerNikonDictionary];
            if(nikonDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerNikonDictionary];
            }
            
            NSDictionary *minoltaDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerMinoltaDictionary];
            if(minoltaDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerMinoltaDictionary];
            }
            
            NSDictionary *fujiDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerFujiDictionary];
            if(fujiDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerFujiDictionary];
            }
            
            NSDictionary *olumpusDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerOlympusDictionary];
            if(olumpusDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerOlympusDictionary];
            }
            
            NSDictionary *pentaxDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerPentaxDictionary];
            if(pentaxDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerPentaxDictionary];
            }
            
            NSDictionary *bim8Dictionary = [item.metaData valueForKey:(NSString*)kCGImageProperty8BIMDictionary];
            if(bim8Dictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImageProperty8BIMDictionary];
            }
            
            NSDictionary *dngDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyDNGDictionary];
            if(dngDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyDNGDictionary];
            }
            
            NSDictionary *exifAuxDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyExifAuxDictionary];
            if(exifAuxDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyExifAuxDictionary];
            }
            
            NSDictionary *openEXRDDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyOpenEXRDictionary];
            if(openEXRDDictionary){
                [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyOpenEXRDictionary];
            }
            
            NSDictionary *appleDictionary = [item.metaData valueForKey:(NSString*)kCGImagePropertyMakerAppleDictionary];
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
        }
    }
}


#pragma mark IBActions

- (IBAction)reportButtonAction:(NSButton *)sender {
//    NSWindowController *windowController = [self.storyboard instantiateControllerWithIdentifier:@"VWWReportWindowController"];
//    [[windowController window]makeKeyWindow];
    
    NSViewController *vc = [self.storyboard instantiateControllerWithIdentifier:@"VWWReportViewController"];
    [self presentViewController:vc animator:self];
}


- (IBAction)browseButtonAction:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    
    
    __weak ViewController *weakSelf = self;
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        //        NSString *dir = openPanel.directoryURL.description;
        //        dir = [dir stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""];
        //        NSURL *url = openPanel.directoryURL;
        NSURL *url = openPanel.URLs[0];
        NSString *path = url.path;
        
        [weakSelf seachForFilesInDirectory:path];
        
    }];
}

- (IBAction)writeButtonAction:(id)sender {
    
    [self.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        VWWContentItem *item = self.contents[index];
        
        if(item.isDirectory) return;
        
//        // Root
//        item.metaData[(NSString*)kCGImagePropertyOrientation] = @(5);
//        item.metaData[(NSString*)kCGImagePropertyDPIHeight] = @(88);
//        item.metaData[(NSString*)kCGImagePropertyDPIWidth] = @(88);
        
        //    // Testing stuff
        //    item.metaData[@"Test"] = @"testing";
        //    NSMutableDictionary *testDictionary = [@{}mutableCopy];
        //    testDictionary[@"test1"] = @"one";
        //    testDictionary[@"test2"] = @"two";
        //    item.metaData[@"{TEST}"] = testDictionary;
        
        // {Exif}
        NSProcessInfo *pi = [NSProcessInfo processInfo];
        NSString *appName = [pi processName];
        NSMutableDictionary *exifDictionary = item.metaData[(NSString*)kCGImagePropertyExifDictionary];
        exifDictionary[(NSString*)kCGImagePropertyExifMakerNote] = [NSString stringWithFormat:@"Modified by %@", appName];
        
        // {GPS}
        NSMutableDictionary *gpsDictionary = [@{}mutableCopy];
        [self applyCoordinate:self.mapView.centerCoordinate toGPSDictionary:gpsDictionary];
        item.metaData[(NSString*)kCGImagePropertyGPSDictionary] = gpsDictionary;
        
        [self writeMetadata:item.metaData toURL:item.url completionBlock:^(BOOL success, NSDictionary *dictionary) {
            if(success){
                item.metaData = [dictionary mutableCopy];

            } else {
                
            }
        }];
        
        

    }];

    [self.tableView reloadDataForRowIndexes:self.selectedIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns - 1)]];
    
}

- (IBAction)eraseGPSButtonAction:(NSButton *)sender {
    
    [self.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        VWWContentItem *item = self.contents[index];
        
        if(item.isDirectory) return;
        
        
        
        // {GPS}
        [item.metaData removeObjectForKey:(NSString*)kCGImagePropertyGPSDictionary];
        
        [self writeMetadata:item.metaData toURL:item.url completionBlock:^(BOOL success, NSDictionary *dictionary) {
            if(success){
                item.metaData = [dictionary mutableCopy];
            } else {
                
            }
        }];
        
        
        
    }];
    
    [self.tableView reloadDataForRowIndexes:self.selectedIndexes columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns - 1)]];
    
}

- (IBAction)centerMapButtonAction:(NSButton *)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
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
    
    
    VWWContentItem *item = self.contents[self.selectedIndexes.firstIndex];
    NSDictionary *dictionary = item.metaData[key];
    
    if([key rangeOfString:@"{"].location == 0){
        if(dictionary){
            self.metadataTextView.string = dictionary.description;
        } else {
            self.metadataTextView.string = @"Error";
        }
    } else if([key isEqualToString:@"All"]){
        self.metadataTextView.string = item.metaData.description;
    }
}


-(void)tableViewAction:(NSTableView*)sender {
    NSLog(@"%s", __FUNCTION__);
}

-(void)tableViewDoubleAction:(NSTableView*)sender{
    NSLog(@"%s", __FUNCTION__);
    VWWContentItem  *item = self.contents[self.selectedIndexes.firstIndex];
    if(item.isDirectory){
        [self seachForFilesInDirectory:item.path];
    } else {
        
    }
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


@end
