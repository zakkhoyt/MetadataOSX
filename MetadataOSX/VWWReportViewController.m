//
//  VWWReportViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/10/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//
//jpg
//jpeg
//jif
//jfif
//exif
//tif
//tiff
//raw
//gif
//bmp
//png
//ppm
//pmg
//pbm
//pnm
//webp
//
//jp2
//jpx
//j2k
//j2c
//fpx
//pdc
//pdf

#import "VWWReportViewController.h"
@import ImageIO;

@interface VWWReportViewController ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSPathControl *pathControl;
@property (strong) NSMutableArray *files;
@property (weak) IBOutlet NSTextField *currentPathLabel;

@end

@implementation VWWReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.files = [@[]mutableCopy];
    NSString *initialDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"initialDir"];
    self.pathControl.URL = [NSURL fileURLWithPath:initialDir];
    self.currentPathLabel.stringValue = @"";
}


- (IBAction)startButtonAction:(id)sender {
    [self.files removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self findFiles:self.pathControl.URL.path];
        self.currentPathLabel.stringValue = @"Finished";
    });
}


-(void)findFiles:(NSString*)path{
    //    NSLog(@"Examining dir: %@", path);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string = [NSString stringWithFormat:@"Looking in %@.\nFound %ld without GPS tags\n%@",
                                path,
                                (long)self.files.count,
                                self.files.description];
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
            // Recursion
            [self findFiles:url.path];
        } else {
            
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
