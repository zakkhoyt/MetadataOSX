//
//  ViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/8/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "ViewController.h"
#import "VWWContentItem.h"
@import MapKit;

@import ImageIO;

typedef void (^VWWEmptyBlock)(void);

@interface ViewController ()
@property (strong) NSMutableArray *contents;
@property (strong) VWWContentItem *selectedItem;

@property (weak) IBOutlet NSTableView *tableView;
@property (unsafe_unretained) IBOutlet NSTextView *metadataTextView;
@property (weak) IBOutlet MKMapView *mapView;

@end

@implementation ViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
                                    
    NSString *picturesDirectory = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Pictures"];
    [self seachForFilesInDirectory:picturesDirectory];

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
                                    
    // Update the view, if already loaded.
                                
}




-(void)seachForFilesInDirectory:(NSString*)path{
    
//    self.progressIndicator.backgroundFilters = nil;
//    [self.progressIndicator startAnimation:self];
//    [self.progressView setLayer:self.progressViewCALayer];
    

    self.contents = [@[]mutableCopy];
    [self getDirectoryAtPath:path completion:^{
//        [self.delegate fileViewController:self setWindowTitle:path];
        [self.tableView reloadData];
        
//        // Store for later incase we need to up one dir.
//        self.currentDirectory = path;
//        [self.progressIndicator stopAnimation:self];
//        [self.progressView setLayer:nil];
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
            parentDirectory.url = [NSURL URLWithString:[NSString stringWithFormat:@"file://localhost%@", parentDirectory.path]];
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
                NSLog(@"added %@", item.path);
//                if(self.filterType == VWWFileFilterTypeAll){
//                    [self.contents addObject:item];
//                }
//                else if(self.filterType == VWWFileFilterTypeWithoutGPSDataOnly){
//                    if([item hasGPSData] == NO ||
//                       item.isDirectory == YES){
//                        [self.contents addObject:item];
//                    }
//                }
//                else if(self.filterType == VWWFileFilterTypeWithGPSDataOnly){
//                    if([item hasGPSData] == YES ||
//                       item.isDirectory == YES){
//                        [self.contents addObject:item];
//                    }
//                }
//                else if(self.filterType == VWWFileFilterTypeCustom){
//                    // If checkbos is set, ensure file has that type of tag
//                    // TODO: This code can be shortened
//                    BOOL hasRequiredTags = YES;
//                    if((self.fileTagFilterType & VWWFileTagFilterTypeHasGeneral) == VWWFileTagFilterTypeHasGeneral){
//                        if([item hasGeneralData] == NO){
//                            hasRequiredTags = NO;
//                        }
//                    }
//                    if((self.fileTagFilterType & VWWFileTagFilterTypeHasGPS) == VWWFileTagFilterTypeHasGPS){
//                        if([item hasGPSData] == NO){
//                            hasRequiredTags = NO;
//                        }
//                    }
//                    if((self.fileTagFilterType & VWWFileTagFilterTypeHasEXIF) == VWWFileTagFilterTypeHasEXIF){
//                        if([item hasEXIFData] == NO){
//                            hasRequiredTags = NO;
//                        }
//                    }
//                    if((self.fileTagFilterType & VWWFileTagFilterTypeHasTIFF) == VWWFileTagFilterTypeHasTIFF){
//                        if([item hasTIFFData] == NO){
//                            hasRequiredTags = NO;
//                        }
//                    }
//                    if((self.fileTagFilterType & VWWFileTagFilterTypeHasJFIF) == VWWFileTagFilterTypeHasJFIF){
//                        if([item hasJFIFData] == NO){
//                            hasRequiredTags = NO;
//                        }
//                    }
//                    
//                    if(hasRequiredTags == YES){
//                        [self.contents addObject:item];
//                    }
//                }
                
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



#pragma mark Implements NSTableViewDataSource
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if([tableColumn.identifier isEqualToString:@"type"]){
        VWWContentItem *item = self.contents[row];
        cellView.textField.stringValue = item.isDirectory ? @"Dir" : @"File";
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
        if(item.isDirectory){
            cellView.imageView.image = [NSImage imageNamed:@"folder.png"];
        }
        else{
            cellView.imageView.image = [NSImage imageNamed:@"photo.png"];
        }
//        cellView.textField.stringValue = item.path;
        NSDictionary *gpsDictionary = [item.metaData valueForKeyPath:@"{GPS}"];
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
            cellView.textField.stringValue = [NSString stringWithFormat:@"%@,%@", latitudeString, longitudeString];
        } else {
            cellView.textField.stringValue = @"n/a";
        }
        
    } else if([tableColumn.identifier isEqualToString:@"location"]){
        
    }
    return cellView;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.contents.count;
}

// Catch keyboard
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    //    NSLog(@"%s", __FUNCTION__);
    
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow != -1) {
        VWWContentItem  *item = self.contents[selectedRow];
        self.selectedItem = item;
        self.metadataTextView.string = item.metaData.description;
        
        // Coords
        NSDictionary *gpsDictionary = [item.metaData valueForKeyPath:@"{GPS}"];
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

            [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(lat, lon) animated:YES];
        }
    }
}


#pragma mark Implements NSTableViewDelegate

- (IBAction)tableViewAction:(id)sender {
        NSLog(@"%s", __FUNCTION__);
//    NSIndexSet *selectedRows = [self.tableView selectedRowIndexes];
//    [self.selectedItems removeAllObjects];
//    NSMutableArray *indexes = [@[]mutableCopy];
//    [selectedRows indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
//        [indexes addObject:@(idx)];
//        return YES;
//    }];
//    
//    for(NSInteger index = 0; index < indexes.count; index++){
//        NSInteger i = ((NSNumber*)indexes[index]).integerValue;
//        VWWContentItem *item = self.contents[i];
//        [self.selectedItems addObject:item];
//    }
}

-(void)tableViewDoubleAction:(id)sender{
    NSLog(@"%s", __FUNCTION__);
//    NSInteger selectedRow = [self.tableView selectedRow];
//    if (selectedRow != -1) {
//        VWWContentItem  *item = self.contents[selectedRow];
//        if(item.isDirectory == YES){
//            [self seachForFilesInDirectory:item.path];
//        }
//        //        NSDictionary *photoTags = [self photoTagsFromFile:item.path];
//        //        if(photoTags){
//        //            NSLog(@"photoTags=%@" ,photoTags);
//        //            item.metaData = [photoTags mutableCopy];
//        //            [self.delegate fileViewController:self item:item];
//        //        }
//    }
//    
}

//- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
//    NSDictionary *aNotification.userInfo
//}
//

//- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
//        self.contents[
////    CGImageSourceCreateWithData(someCFDataRef, nil);
////    CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(imgSource, 0, nil);
//}




@end
