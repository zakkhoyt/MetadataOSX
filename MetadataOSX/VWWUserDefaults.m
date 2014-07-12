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

@implementation VWWUserDefaults


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
