//
//  VWWContentItem.m
//  PhotoGeoTagger
//
//  Created by Zakk Hoyt on 4/14/13.
//  Copyright (c) 2013 Zakk Hoyt. All rights reserved.
//

#import "VWWContentItem.h"



@implementation VWWContentItem

-(id)init{
    self = [super init];
    if(self){
        _dictionaries = [[NSMutableDictionary alloc]init];
    }
    return self;
}

-(BOOL)hasDataWithTag:(NSString*)tag{
    if(self.metaData == nil) return NO;
    for(NSString *key in [self.metaData allKeys]){
        if([key isEqualToString:tag]){
            return YES;
        }
    }
    return NO;
}

// TODO: These strings are already declared as keys elsewhere in the app.
// Let's reuse them.
-(BOOL)hasGeneralData{
    return (BOOL)([self.metaData allKeys].count);
}
-(BOOL)hasGPSData{
    return [self hasDataWithTag:@"{GPS}"];
}
-(BOOL)hasJFIFData{
    return [self hasDataWithTag:@"{JFIF}"];
}
-(BOOL)hasTIFFData{
    return [self hasDataWithTag:@"{TIFF}"];
}
-(BOOL)hasEXIFData{
    return [self hasDataWithTag:@"{Exif}"];
}








-(void)setMetaData:(NSMutableDictionary *)metaData{
    @synchronized(self){
        _metaData = metaData;
        [self.dictionaries removeAllObjects];
        self.tiffDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyTIFFDictionary];
        self.gifDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyGIFDictionary];
        self.exifDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyExifDictionary];
        self.exifAuxDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyExifAuxDictionary];
        self.pngDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyPNGDictionary];
        self.iptcDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyIPTCDictionary];
        self.gpsDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyGPSDictionary];
        self.rawDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyRawDictionary];
        self.ciffDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyCIFFDictionary];
        self.bbimDictionary = [self ensureDictionaryForKey:(NSString*)kCGImageProperty8BIMDictionary];
        self.dngDictionary = [self ensureDictionaryForKey:(NSString*)kCGImagePropertyDNGDictionary];
        
        
//        [self.dictionaries addObject:self.tiffDictionary];
//        [self.dictionaries addObject:self.gifDictionary];
//        [self.dictionaries addObject:self.exifDictionary];
//        [self.dictionaries addObject:self.exifAuxDictionary];
//        [self.dictionaries addObject:self.pngDictionary];
//        [self.dictionaries addObject:self.iptcDictionary];
//        [self.dictionaries addObject:self.gpsDictionary];
//        [self.dictionaries addObject:self.rawDictionary];
//        [self.dictionaries addObject:self.ciffDictionary];
//        [self.dictionaries addObject:self.bbimDictionary];
//        [self.dictionaries addObject:self.dngDictionary];

    }
}

-(NSMutableDictionary*)ensureDictionaryForKey:(NSString*)key{
    NSMutableDictionary *dictionary = [[_metaData objectForKey:(NSString*)key]mutableCopy];
    if(!dictionary)
        dictionary = [@[]mutableCopy];
    
//    self.dictionaries[key] = dictionary;
    [self.dictionaries setObject:dictionary forKey:key];
    return dictionary;
}


-(NSString *)description{
    return [NSString stringWithFormat:@"url=%@\n"
            "displayName=%@"
            "path=%@"
            "extension=%@"
            "metaData=%@",
            self.url.absoluteString,
            self.displayName,
            self.path,
            self.extension,
            self.metaData];

}

-(void)setAnnotationCoordinate:(CLLocationCoordinate2D)coordinate{
    _coordinate = coordinate;
}
@end
