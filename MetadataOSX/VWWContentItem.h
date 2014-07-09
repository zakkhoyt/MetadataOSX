//
//  VWWContentItem.h
//  PhotoGeoTagger
//
//  Created by Zakk Hoyt on 4/14/13.
//  Copyright (c) 2013 Zakk Hoyt. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;


@interface VWWContentItem : NSObject <MKAnnotation>
@property BOOL isDirectory;
@property (strong) NSURL *url;
@property (strong) NSString *path;
@property (strong) NSString *displayName;
@property (strong) NSString *extension;
@property (nonatomic, strong) NSMutableDictionary *metaData;
@property (strong) NSMutableDictionary *tiffDictionary;
@property (strong) NSMutableDictionary *gifDictionary;
@property (strong) NSMutableDictionary *jfifDictionary;
@property (strong) NSMutableDictionary *exifDictionary;
@property (strong) NSMutableDictionary *pngDictionary;
@property (strong) NSMutableDictionary *iptcDictionary;
@property (strong) NSMutableDictionary *gpsDictionary;
@property (strong) NSMutableDictionary *rawDictionary;
@property (strong) NSMutableDictionary *ciffDictionary;
@property (strong) NSMutableDictionary *exifAuxDictionary;
@property (strong) NSMutableDictionary *bbimDictionary;
@property (strong) NSMutableDictionary *dngDictionary;
@property (strong) NSMutableDictionary *makerCanonDictionary;
@property (strong) NSMutableDictionary *makerNikonDictionary;
@property (strong) NSMutableDictionary *makerMinoltaDictionary;
@property (strong) NSMutableDictionary *makerFujiDictionary;
@property (strong) NSMutableDictionary *makerOlympusDictionary;
@property (strong) NSMutableDictionary *makerPentaxDictionary;

@property (strong) NSMutableDictionary *dictionaries;




-(BOOL)hasGeneralData;
-(BOOL)hasGPSData;
-(BOOL)hasJFIFData;
-(BOOL)hasTIFFData;
-(BOOL)hasEXIFData;
-(NSString *)description;


// MKAnnotation
-(void)setAnnotationCoordinate:(CLLocationCoordinate2D)coordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@end
