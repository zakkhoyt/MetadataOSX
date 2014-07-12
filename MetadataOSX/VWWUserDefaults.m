//
//  VWWUserDefaults.m
//  Throwback
//
//  Created by Zakk Hoyt on 7/11/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWUserDefaults.h"


static NSString *VWWUserDefaultsInitialPathKey = @"initialPath";

@implementation VWWUserDefaults
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
