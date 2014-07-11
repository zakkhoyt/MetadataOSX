//
//  VWWPlacesController.h
//  Radius_iOS
//
//  Created by Zakk Hoyt on 1/15/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^VWWArrayBlock)(NSArray *array);
typedef void (^VWWStringBlock)(NSString *string);

@interface VWWPlacesController : NSObject
+(void)queryGooglePlacesWithLatitude:(double)latitude longitude:(double)longitude radius:(NSInteger)radius completion:(VWWArrayBlock)completion;
+(void)stringLocalityFromLatitude:(double)latitude longitude:(double)longitude completionBlock:(VWWStringBlock)completionBlock;
@end
