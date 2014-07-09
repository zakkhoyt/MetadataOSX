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

@interface ViewController ()
@property (strong) NSMutableArray *contents;
@property NSUInteger selectedIndex;
@property (weak) IBOutlet NSTextField *pathLabel;

@property (weak) IBOutlet NSTableView *tableView;
@property (unsafe_unretained) IBOutlet NSTextView *metadataTextView;
@property (weak) IBOutlet MKMapView *mapView;
@property (weak) IBOutlet NSSegmentedControl *metadataSegment;
@property (weak) IBOutlet NSPopUpButton *metadataPopup;
@property (weak) IBOutlet NSImageView *imageView;
@property (strong) VWWEmptyBlock completionBlock;
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

-(BOOL)writeMetadata:(NSDictionary*)metadata toURL:(NSURL*)url{
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        NSLog(@"%s Could not create image source for %@", __PRETTY_FUNCTION__, url.path);
        return NO;
    }

    
    NSURL *destURL = [NSURL URLWithString:@"file:///Users/zakkhoyt/__test.jpg"];
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)destURL, kUTTypeJPEG, 1, NULL);
    if(imageDestination == NULL){
        NSLog(@"%s Could not create image destination for %@", __PRETTY_FUNCTION__, url.path);
        return NO;
        
    }
    
    // Get metadata from source then create a mutable copy
    CGImageMetadataRef metadataRef = CGImageSourceCopyMetadataAtIndex(imageSource, 0, NULL);
    CGMutableImageMetadataRef mutableMetadataRef = CGImageMetadataCreateMutableCopy(metadataRef);
    
    // Modify the metadata
    CFStringRef path = CFStringCreateWithFormat(NULL, NULL, CFSTR("{TIFF}.%@"), @"Orientation");
    
    CFTypeRef value = (CFTypeRef)3;
    CGImageMetadataSetValueWithPath(mutableMetadataRef, NULL, path, value);
    NSLog(@"mutableMetadataRef: \n%@", (__bridge NSString*)mutableMetadataRef);
    
    // Write the metadata to imageDestination
    const void *keys[] =   {kCGImageDestinationMetadata};
    const void *values[] = {mutableMetadataRef};
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFErrorRef error;
    bool success = CGImageDestinationCopyImageSource(imageDestination, imageSource, options, &error);
    if(error){
        NSLog(@"An error occurred when copying the file: %@", (__bridge NSString*)error);
    }
    
    
    CFRelease(imageSource);
    CFRelease(imageDestination);

    if(!success){
        NSLog(@"%s Failed to create new image for %@", __PRETTY_FUNCTION__, url.path);
        return NO;
    }
    

    NSLog(@"%s Success", __PRETTY_FUNCTION__);
    return YES;
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
                [SMGooglePlacesController queryGooglePlacesWithLatitude:coordinate.latitude longitude:coordinate.longitude radius:10 completion:^(NSArray *places) {
                    NSLog(@"Places: %@", places);
                    if(places.count){
                        NSDictionary *place = places[0];
                        NSString *name = [place valueForKeyPath:@"name"];
                        cellView.textField.stringValue = name;
                    } else {
                        cellView.textField.stringValue = @"n/a";
                    }
                    //cellView.textField.stringValue = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
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
        self.selectedIndex = selectedRow;
        VWWContentItem  *item = self.contents[self.selectedIndex];
        
        
        if(item.isDirectory){
            self.imageView.image = nil;
            self.metadataTextView.string = @"";
            [self.metadataPopup removeAllItems];
        
            [ViewController animateWithDuration:0.5 animation:^{
                self.mapView.alphaValue = 0.0;
                self.imageView.alphaValue = 0.0;
            } completion:^{
                self.mapView.hidden = YES;
            }];
            
//            [self seachForFilesInDirectory:item.path];
        } else {
            
            self.mapView.hidden = NO;
            [ViewController animateWithDuration:0.5 animation:^{
                self.mapView.alphaValue = 1.0;
                self.imageView.alphaValue = 1.0;
            } completion:^{
            }];

            
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
}


#pragma mark IBActions
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
    VWWContentItem *item = self.contents[self.selectedIndex];
    item.metaData[(NSString*)kCGImagePropertyOrientation] = @(3);
    
    [self writeMetadata:item.metaData toURL:item.url];
}

- (IBAction)metadataPopupAction:(NSPopUpButton *)sender {
    NSString *key = sender.selectedItem.title;
    NSLog(@"Key: %@", key);
    
    VWWContentItem *item = self.contents[self.selectedIndex];
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
    VWWContentItem  *item = self.contents[self.selectedIndex];
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

@end
