//
//  VWWReportViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/10/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//


#import "VWWReportViewController.h"
#import "VWWUserDefaults.h"
@import ImageIO;

@interface VWWReportViewController ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (strong) NSMutableArray *files;
@property (weak) IBOutlet NSTextField *currentPathLabel;
@property (weak) IBOutlet NSButton *imageTypesCheckButton;
@property (strong) NSArray *imageTypes;
@property dispatch_queue_t reportQueue;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *startButton;

@end

@implementation VWWReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reportQueue = dispatch_queue_create("com.vaporwarewolf.throwback.report", DISPATCH_QUEUE_SERIAL);
    [self setupImageTypes];
    
    
    
    
}

-(void)viewWillAppear{
    [super viewWillAppear];
    self.files = [@[]mutableCopy];
    NSString *initialPath = [VWWUserDefaults initialPath];
    self.currentPathLabel.stringValue = @"See preferences to define file types and properties";
    self.view.window.title = initialPath;
    self.progressIndicator.hidden = YES;
}

-(void)viewDidAppear{
    [super viewDidAppear];
//    [self startButtonAction:nil];
}


- (IBAction)startButtonAction:(id)sender {
    [self.files removeAllObjects];
    [self.progressIndicator startAnimation:self];
    self.startButton.enabled = NO;
    self.progressIndicator.hidden = NO;
    
    // To simplify things we'll use a serial queue. We won't need to worry about critical sections.
    dispatch_async(self.reportQueue, ^{
        [self findFiles:[VWWUserDefaults initialPath]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentPathLabel.stringValue = [NSString stringWithFormat:@"Found %ld photos without GPS tags in %@", (long)self.files.count, [VWWUserDefaults initialPath]];
            [self.progressIndicator stopAnimation:self];
            self.startButton.enabled = YES;
            self.progressIndicator.hidden = YES;
        });
    });
}


-(void)findFiles:(NSString*)path{
    //    NSLog(@"Examining dir: %@", path);

    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.textView.string = [NSString stringWithFormat:@"Looking in %@.\nFound %ld without GPS tags\n%@",
                                path,
                                (long)self.files.count,
                                self.files.description];
        //        NSLog(@"%@", [NSString stringWithFormat:@"Looking in %@.\nFound %ld without GPS tags\n%@",
        //                      path,
        //                      (long)self.files.count,
        //                      self.files.description]);
        self.currentPathLabel.stringValue = path;
        
    });
    
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *contents = [[fileManager contentsOfDirectoryAtPath:path error:&error]mutableCopy];
    
    for(NSInteger index = 0; index < contents.count; index++){
        
        NSString *contentDetailsPath = [NSString stringWithFormat:@"%@/%@", path, contents[index]];
        contentDetailsPath = [contentDetailsPath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
        
        NSDictionary *contentsAttributes = [fileManager attributesOfItemAtPath:contentDetailsPath error:&error];
        
        BOOL isDirectory = contentsAttributes[NSFileType] == NSFileTypeDirectory ? YES : NO;
        
        NSURL *url = [NSURL fileURLWithPath:contentDetailsPath isDirectory:isDirectory];
        
        if(isDirectory){
            if([url.path rangeOfString:@"iPhoto Library.photolibrary"].location == NSNotFound){
                // Recurse
//                dispatch_async(self.reportQueue, ^{
                    [self findFiles:url.path];
//                });
            }
        } else {
            BOOL shouldInspectMetadata = NO;
            if(self.imageTypesCheckButton.state == NSOnState){
                shouldInspectMetadata = [self urlIsImageType:url];
            } else {
                shouldInspectMetadata = YES;
            }
            
            if(shouldInspectMetadata){
                NSDictionary *metadata = [self readMetadataFromURL:url];
                NSDictionary *gpsDictionary = metadata[(NSString*)kCGImagePropertyGPSDictionary];
                if(gpsDictionary == nil) {
                    [self.files insertObject:url.path atIndex:0];
                    continue;
                }
                
                NSNumber *latitude = gpsDictionary[(NSString*)kCGImagePropertyGPSLatitude];
                NSNumber *longitude = gpsDictionary[(NSString*)kCGImagePropertyGPSLongitude];
                if(latitude == nil && longitude == nil){
                    [self.files insertObject:url.path atIndex:0];
                }
            }
        }
    }
}


-(void)setupImageTypes{
    self.imageTypes = @[
                        @"jpg",
                        @"jpeg",
                        @"jif",
                        @"jfif",
                        @"tif",
                        @"tiff",
                        @"exif",
                        @"raw",
                        @"gif",
                        @"bmp",
                        @"png",
                        @"ppm",
                        @"pmg",
                        @"pbm",
                        @"pnm",
                        @"webp",
                        @"jp2",
                        @"jpx",
                        @"j2k",
                        @"j2c",
                        @"fpx",
                        @"pdc",
                        @"pdf"
                        ];
}

-(BOOL)urlIsImageType:(NSURL*)url{
    NSString *extension = [url.path pathExtension];

    for(NSString *imageType in self.imageTypes){
        if([extension compare:imageType options:NSCaseInsensitiveSearch] == NSOrderedSame) return YES;
    }
    
    return NO;
}

-(NSDictionary*)readMetadataFromURL:(NSURL*)url{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (imageSource == NULL) {
        //        NSLog(@"Could not read metadata for %@", url.path);
        return nil;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], (NSString *)kCGImageSourceShouldCache,
                             nil];
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    NSDictionary *metadata = nil;
    if (imageProperties) {
        metadata = (__bridge NSDictionary *)(imageProperties);
        CFRelease(imageProperties);
    }
    CFRelease(imageSource);
    
    return metadata;
}




@end
