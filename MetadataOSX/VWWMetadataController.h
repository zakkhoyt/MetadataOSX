//
//  VWWMetadataController.h
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/10/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;


typedef void (^VWWBoolDictionaryBlock)(BOOL success, NSDictionary *dictionary);
typedef void (^VWWCLLocationCoordinate2DBlock)(CLLocationCoordinate2D coordinate);

@interface VWWMetadataController : NSObject
+(NSDictionary*)readMetadataFromURL:(NSURL*)url;
+(void)writeMetadata:(NSDictionary*)metadata toURL:(NSURL*)url completionBlock:(VWWBoolDictionaryBlock)completionBlock;

+(void)extractLocationFromGPSDictionary:(NSDictionary*)gpsDictionary completionBlock:(VWWCLLocationCoordinate2DBlock)completionBlock;
+(void)applyCoordinate:(CLLocationCoordinate2D)coordinate toGPSDictionary:(NSMutableDictionary*)gpsDictionary;
@end
