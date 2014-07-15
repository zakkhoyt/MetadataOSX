//
//  VWWUserDefaults.m
//  Throwback
//
//  Created by Zakk Hoyt on 7/11/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWUserDefaults.h"


static NSString *VWWUserDefaultsInitialPathKey = @"initialPath";
static NSString *VWWUserDefaultsAllowedTypesKey = @"allowedTypes";
static NSString *VWWUserDefaultsRecentLocationsKey = @"recentLocations";
static NSString *VWWUserDefaultsFileTypesRadioKey = @"fileTypesRadio";
static NSString *VWWUserDefaultsGPSRadioKey = @"GPSRadio";
static NSString *VWWUserDefaultsEXIFRadioKey = @"EXIFRadio";

@implementation VWWUserDefaults



+(NSUInteger)GPSRadio{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:VWWUserDefaultsGPSRadioKey];
    return number ? number.unsignedIntegerValue : 2;
}
+(void)setGPSRadio:(NSUInteger)GPSRadio{
    [[NSUserDefaults standardUserDefaults] setObject:@(GPSRadio) forKey:VWWUserDefaultsGPSRadioKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSUInteger)EXIFRadio{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:VWWUserDefaultsEXIFRadioKey];
    return number ? number.unsignedIntegerValue : 2;
}
+(void)setEXIFRadio:(NSUInteger)EXIFRadio{
    [[NSUserDefaults standardUserDefaults] setObject:@(EXIFRadio) forKey:VWWUserDefaultsEXIFRadioKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



+(NSUInteger)fileTypesRadio{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:VWWUserDefaultsFileTypesRadioKey];
    return number ? number.unsignedIntegerValue : 1;
}
+(void)setFileTypesRadio:(NSUInteger)fileTypesRadio{
    [[NSUserDefaults standardUserDefaults] setObject:@(fileTypesRadio) forKey:VWWUserDefaultsFileTypesRadioKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




+(NSArray*)recentLocations{
    NSArray *locations = [[NSUserDefaults standardUserDefaults] objectForKey:VWWUserDefaultsRecentLocationsKey];
    return locations;
}

+(void)setRecentLocations:(NSArray*)recentLocations{
    if(recentLocations == nil){
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:VWWUserDefaultsRecentLocationsKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:recentLocations forKey:VWWUserDefaultsRecentLocationsKey];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}


+(NSString*)allowedTypes{
    NSString *allowedTypes = [[NSUserDefaults standardUserDefaults] objectForKey:VWWUserDefaultsAllowedTypesKey];
    if(allowedTypes == nil){
        allowedTypes = @"jpg | jpeg | bmp | gif | png";
    }
    return allowedTypes;
}
+(void)setAllowedTypes:(NSString*)allowedTypes{
    [[NSUserDefaults standardUserDefaults] setObject:allowedTypes forKey:VWWUserDefaultsAllowedTypesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}




+(NSString*)initialPath{
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:VWWUserDefaultsInitialPathKey];
    if(path == nil){
        path = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Pictures"];
    }
    return path;
}
+(void)setInitialPath:(NSString*)initialPath{
    [[NSUserDefaults standardUserDefaults] setObject:initialPath forKey:VWWUserDefaultsInitialPathKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
