//
//  VWWMetadataController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/10/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWMetadataController.h"

@implementation VWWMetadataController


+(NSDictionary*)readMetadataFromURL:(NSURL*)url{
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

+(void)writeMetadata:(NSDictionary*)metadata toURL:(NSURL*)url completionBlock:(VWWBoolDictionaryBlock)completionBlock{
    
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



+(void)extractLocationFromGPSDictionary:(NSDictionary*)gpsDictionary completionBlock:(VWWCLLocationCoordinate2DBlock)completionBlock{
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

+(void)applyCoordinate:(CLLocationCoordinate2D)coordinate toGPSDictionary:(NSMutableDictionary*)gpsDictionary{
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
@end
