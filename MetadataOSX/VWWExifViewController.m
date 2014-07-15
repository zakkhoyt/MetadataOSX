//
//  VWWExifViewController.m
//  Throwback
//
//  Created by Zakk Hoyt on 7/12/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//
//
//


#import "VWWExifViewController.h"
#import "FileSystemItem.h"
@import ImageIO;
@interface VWWExifViewController ()
@property (weak) IBOutlet NSPopUpButton *dictionaryPopup;

@property (weak) IBOutlet NSTableView *exifTableView;
@property (strong) NSArray *bim8;
@property (strong) NSArray *ciff;
@property (strong) NSArray *dictionaries;
@property (strong) NSArray *dng;
@property (strong) NSArray *exif;
@property (strong) NSArray *exifAux;
@property (strong) NSArray *gif;
@property (strong) NSArray *gps;
@property (strong) NSArray *iptc;
@property (strong) NSArray *makerCanon;
@property (strong) NSArray *makerNikon;
@property (strong) NSArray *jfif;
@property (strong) NSArray *png;
@property (strong) NSArray *tiff;
@end

@implementation VWWExifViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildDataStructures];
    
//    NSArray *displayNames = [self.dictionaries valueForKeyPath:@"displayName"];
        NSArray *displayNames = [self.dictionaries valueForKeyPath:@"key"];
    [self.dictionaryPopup removeAllItems];
    [self.dictionaryPopup addItemsWithTitles:displayNames];
    [self.dictionaryPopup selectItemAtIndex:0];
    
    [self.exifTableView reloadData];
}

-(void)viewWillAppear{
    [super viewWillAppear];
    
    self.view.window.title = self.item.fullPath.lastPathComponent;
}

-(NSString*)keyStringForIndex:(NSUInteger)index{
    NSDictionary *dictionary = self.exif[index];
    return dictionary[@"key"];
    
}

-(NSArray*)arrayFromSelectedIndex{
    NSUInteger index = self.dictionaryPopup.indexOfSelectedItem;
    NSDictionary *dictionary = self.dictionaries[index];
    NSArray *value = dictionary[@"value"];
    return value;
}


-(NSString*)keyFromSelectedIndex{
    NSUInteger index = self.dictionaryPopup.indexOfSelectedItem;
    NSDictionary *dictionary = self.dictionaries[index];
    NSString *key = dictionary[@"key"];
    return key;
}

#pragma mark IBActions
- (IBAction)dictionaryPopupAction:(id)sender {
    [self.exifTableView reloadData];
}

- (IBAction)valueCellAction:(NSTextFieldCell *)sender {
    NSInteger row = self.exifTableView.selectedRow;
//    NSInteger col = self.exifTableView.selectedColumn;
    
    NSArray *array = [self arrayFromSelectedIndex];
//    NSString *dictionaryKey = [self keyFromSelectedIndex];
    NSDictionary *dictionary = array[row];
    NSString *key = dictionary[@"key"];
    NSLog(@"%s Edited %@", __PRETTY_FUNCTION__, key);
    
//    dictionary[@"key"] = sender.stringValue;
    
//    id value = dictionary[key];
//    if(value == nil){
//        //displayValue = @"-";
//    } else if([value isKindOfClass:[NSString class]]){
////        displayValue = (NSString*)value;
//    } else if([value isKindOfClass:[NSNumber class]]){
////        displayValue = ((NSNumber*)value).stringValue;
//    } else if([value isKindOfClass:[NSArray class]]){
////        displayValue = @"n/a {array}";
//    } else if([value isKindOfClass:[NSDictionary class]]){
////        displayValue = @"n/a {dictionary}";
//    } else if([value isKindOfClass:[NSData class]]){
////        displayValue = @"n/a {data}";
//    }
//
    
        NSLog(@"%s Edited %@", __PRETTY_FUNCTION__, key);
}
- (IBAction)anotherAction:(NSTextField *)sender {
        NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark Implements NSTableViewDataSource
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSArray *array = [self arrayFromSelectedIndex];
    NSString *dictionaryKey = [self keyFromSelectedIndex];
    NSDictionary *metadataDictionary = self.item.metadata[dictionaryKey];
    NSDictionary *dictionary = array[row];
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if([tableColumn.identifier isEqualToString:@"key"]){
        NSString *key = dictionary[@"key"];
        cellView.textField.stringValue = key;
    } else if([tableColumn.identifier isEqualToString:@"value"]){
        cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        [cellView.textField setEditable:YES]; // Make Cell Editable!
        
        
        NSString *key = dictionary[@"key"];
        id value = metadataDictionary[key];
        NSString *displayValue;
        if(value == nil){
            displayValue = @"-";
        } else if([value isKindOfClass:[NSString class]]){
            displayValue = (NSString*)value;
        } else if([value isKindOfClass:[NSNumber class]]){
            displayValue = ((NSNumber*)value).stringValue;
        } else if([value isKindOfClass:[NSArray class]]){
            displayValue = @"n/a {array}";
        } else if([value isKindOfClass:[NSDictionary class]]){
            displayValue = @"n/a {dictionary}";
        } else if([value isKindOfClass:[NSData class]]){
            displayValue = @"n/a {data}";
        }
        cellView.textField.stringValue = displayValue;
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSArray *array = [self arrayFromSelectedIndex];
    return array.count;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
}



#pragma mark NSTableViewDelegate




-(void)buildDataStructures{
    self.bim8 = @[
                  @{@"key" : @"LayerNames",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Version",@"value" : [NSNull null],@"edited" : @(0)},
                  ];
    
    self.ciff = @[
                  @{@"key" : @"CameraSerialNumber",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContinuousDrive",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Description",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Firmware",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"FlashExposureComp",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"FocusMode",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ImageFileName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ImageName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ImageSerialNumber",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"LensMaxMM",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"LensMinMM",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"LensModel",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"MeasuredEV",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"MeteringMode",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"OwnerName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"RecordID",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReleaseMethod",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReleaseTiming",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"SelfTimingTime",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ShootingMode",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"WhiteBalanceIndex",@"value" : [NSNull null],@"edited" : @(0)},
                  ];
    self.dng = @[
                 @{@"key" : @"BackwardVersion",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"CameraSerialNumber",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"LensInfo",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"LocalizedCameraModel",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"UniqueCameraModel",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Version",@"value" : [NSNull null],@"edited" : @(0)},
                 ];
    
    self.exif = @[
                  @{@"key" : @"ApertureValue",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"BodySerialNumber",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"BrightnessValue",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"CameraOwnerName",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"CFAPattern",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ColorSpace",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ComponentsConfiguration",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"CompressedBitsPerPixel",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"Contrast",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"CustomRendered",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"DateTimeDigitized",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"DateTimeOriginal",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"DeviceSettingDescription",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"DigitalZoomRatio",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ExposureBiasValue",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ExposureIndex",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ExposureMode",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ExposureProgram",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ExposureTime",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FileSource",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"Flash",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FlashEnergy",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FlashPixVersion",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FNumber",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FocalLength",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FocalLenIn35mmFilm",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FocalPlaneResolutionUnit",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FocalPlaneXResolution",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"FocalPlaneYResolution",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"GainControl",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"Gamma",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ImageUniqueID",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ISOSpeed",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ISOSpeedLatitudeyyy",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ISOSpeedLatitudezzz",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ISOSpeedRatings",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"LensMake",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"LensModel",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"LensSerialNumber",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"LensSpecification",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"LightSource",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"MakerNote",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"MaxApertureValue",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"MeteringMode",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"OECF",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"PixelXDimension",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"PixelYDimension",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"RecommendedExposureIndex",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"RelatedSoundFile",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"Saturation",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SceneCaptureType",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SceneType",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SensingMethod",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SensitivityType",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"Sharpness",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"ShutterSpeedValue",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SpatialFrequencyResponse",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SpectralSensitivity",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"StandardOutputSensitivity",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubjectArea",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubjectDistance",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubjectDistRange",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubjectLocation",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubsecTime",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubsecTimeDigitized",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"SubsecTimeOrginal",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"UserComment",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"Version",  @"value" : [NSNull null],  @"edited" : @(0)},
                  @{@"key" : @"WhiteBalance",  @"value" : [NSNull null],  @"edited" : @(0)},
                  ];
    
    self.exifAux = @[
                     @{@"key" : @"Firmware", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"FlashCompensation", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"ImageNumber", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"LensID ", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"LensInfo", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"LensModel ", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"LensSerialNumber", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"OwnerName", @"value" : [NSNull null], @"edited" : @(0)},
                     @{@"key" : @"SerialNumber", @"value" : [NSNull null], @"edited" : @(0)},
                     
                     ];
    
    self.gif = @[
                 @{@"key" : @"DelayTime",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"HasGlobalColorMap",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"ImageColorMap",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"LoopCount",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"UnclampedDelayTime",@"value" : [NSNull null],@"edited" : @(0)},
                 ];
    
    self.gps = @[
                 @{@"key" : @"Altitude",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"AltitudeRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"AreaInformation",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DateStamp",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestBearing",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestBearingRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestDistance",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestDistanceRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestLatitude",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestLatitudeRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestLongitude",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DestLongitudeRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Differental",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"DOP",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"HPositioningError",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"ImgDirection",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"ImgDirectionRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Latitude",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"LatitudeRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Longitude",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"LongitudeRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"MapDatum",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"MeasureMode",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"ProcessingMethod",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Satellites",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Speed",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"SpeedRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Status",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"TimeStamp",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Track",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"TrackRef",@"value" : [NSNull null],@"changed" : @(0)},
                 @{@"key" : @"Version",@"value" : [NSNull null],@"changed" : @(0)},
                 ];
    
    self.iptc = @[
                  @{@"key" : @"ActionAdvised",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Byline",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"BylineTitle",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"CaptionAbstract",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Category",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"City",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Contact",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoAddress",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoCity",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoCountry",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoEmails",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoPhones",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoPostalCode",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoStateProvince",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContactInfoWebURLs",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContentLocationCode",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ContentLocationName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"CopyrightNotice",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"CountryPrimaryLocationCode",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"CountryPrimaryLocationName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"CreatorContactInfo",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Credit",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"DateCreated",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"DigitalCreationDate",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"DigitalCreationTime",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"EditorialUpdate",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"EditStatus",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ExpirationDate",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ExpirationTime",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"FixtureIdentifier",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Headline",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ImageOrientation",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ImageType",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Keywords",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"LanguageIdentifier",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ObjectAttributeReference",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ObjectCycle",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ObjectName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ObjectTypeReference",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"OriginalTransmissionReference",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"OriginatingProgram",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ProgramVersion",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ProvinceState",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReferenceDate",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReferenceNumber",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReferenceService",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReleaseDate",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ReleaseTime",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"RightsUsageTerms",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Scene",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Source",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"SpecialInstructions",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"StarRating",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"SubjectReference",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"SubLocation",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"SupplementalCategory",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"TimeCreated",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Urgency",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"WriterEditor",@"value" : [NSNull null],@"edited" : @(0)},
                  ];
    self.jfif = @[
                  @{@"key" : @"DensityUnit",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"IsProgressive",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Version",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"XDensity",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"YDensity",@"value" : [NSNull null],@"edited" : @(0)},
                  ];
    
    self.makerCanon = @[
                        @{@"key" : @"AspectRatioInfo",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"CameraSerialNumber",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ContinuousDrive",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"Firmware",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"FlashExposureComp",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ImageSerialNumber",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"LensModel",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"OwnerName",@"value" : [NSNull null],@"edited" : @(0)},
                        ];
    
    self.makerNikon = @[
                        @{@"key" : @"CameraSerialNumber",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ColorMode",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"DigitalZoom",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"FlashExposureComp",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"FlashSetting",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"FocusDistance",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"FocusMode",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ImageAdjustment",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ISOSelection",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ISOSetting",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"LensAdapter",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"LensInfo",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"LensType",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"Quality",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"SharpenMode",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ShootingMode",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"ShutterCount",@"value" : [NSNull null],@"edited" : @(0)},
                        @{@"key" : @"WhiteBalanceMode",@"value" : [NSNull null],@"edited" : @(0)},
                        ];
    
    self.png = @[
                 @{@"key" : @"Author",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Chromaticities",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Copyright",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"CreationTime",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"DelayTime",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Description",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Gamma",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"InterlaceType",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"LoopCount",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"ModificationTime",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Software",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"sRGBIntent",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"Title",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"UnclampedDelayTime",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"XPixelsPerMeter",@"value" : [NSNull null],@"edited" : @(0)},
                 @{@"key" : @"YPixelsPerMeter",@"value" : [NSNull null],@"edited" : @(0)},
                 ];
    
    self.tiff = @[
                  @{@"key" : @"Artist",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Compression",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Copyright",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"DateTime",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"DocumentName",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"HostComputer",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ImageDescription",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Make",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Model",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Orientation",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"PhotometricInterpretation",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"PrimaryChromaticities",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"ResolutionUnit",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"Software",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"TransferFunction",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"WhitePoint",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"XResolution",@"value" : [NSNull null],@"edited" : @(0)},
                  @{@"key" : @"YResolution",@"value" : [NSNull null],@"edited" : @(0)},
                  ];
    
    
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyTIFFDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyGIFDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyJFIFDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyExifDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyPNGDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyIPTCDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyGPSDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyRawDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyCIFFDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerCanonDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerNikonDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerMinoltaDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerFujiDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerOlympusDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerPentaxDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImageProperty8BIMDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyDNGDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyExifAuxDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_4_0);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyOpenEXRDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_NA);
    //IMAGEIO_EXTERN const CFStringRef kCGImagePropertyMakerAppleDictionary  IMAGEIO_AVAILABLE_STARTING(__MAC_10_10, __IPHONE_7_0);

//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyTIFFDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyGIFDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyJFIFDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyExifDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyPNGDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyIPTCDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyGPSDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyRawDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyCIFFDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerCanonDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerNikonDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerMinoltaDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerFujiDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerOlympusDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerPentaxDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImageProperty8BIMDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyDNGDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyExifAuxDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyOpenEXRDictionary]);
//    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyMakerAppleDictionary]);
    //    NSLog(@"%@", [NSString stringWithFormat:@"%@", (NSString*)kCGImagePropertyIPTCDictionary]);
//    2014-07-12 14:50:56.857 Throwback[16001:597268] {TIFF}
//    2014-07-12 14:50:56.857 Throwback[16001:597268] {GIF}
//    2014-07-12 14:50:56.857 Throwback[16001:597268] {JFIF}
//    2014-07-12 14:50:56.857 Throwback[16001:597268] {Exif}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {PNG}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {GPS}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {CIFF}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {MakerCanon}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {MakerNikon}
//    2014-07-12 14:50:56.859 Throwback[16001:597268] {8BIM}
//    2014-07-12 14:50:56.859 Throwback[16001:597268] {DNG}
//    2014-07-12 14:50:56.859 Throwback[16001:597268] {ExifAux}
    
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {Raw}
//    2014-07-12 14:50:56.859 Throwback[16001:597268] {EXR}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {MakerFuji}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {MakerOlympus}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {MakerPentax}
//    2014-07-12 14:50:56.858 Throwback[16001:597268] {MakerMinolta}
//    2014-07-12 14:50:56.859 Throwback[16001:597268] {MakerApple}
    
    self.dictionaries = @[@{@"displayName" : @"8BIM",@"key" : @"{8BIM}",@"value" : self.bim8},
                          @{@"displayName" : @"CIFF",@"key" : @"{CIFF}",@"value" : self.ciff},
                          @{@"displayName" : @"DNG",@"key" : @"{DNG}",@"value" : self.dng},
                          @{@"displayName" : @"Exif",@"key" : @"{Exif}",@"value" : self.exif},
                          @{@"displayName" : @"ExifAux",@"key" : @"{ExifAux}",@"value" : self.exifAux},
                          @{@"displayName" : @"GIF",@"key" : @"{GIF}",@"value" : self.gif},
                          @{@"displayName" : @"GPS",@"key" : @"{GPS}",@"value" : self.gps},
                          @{@"displayName" : @"IPTC",@"key" : @"{IPTC}",@"value" : self.iptc},
                          @{@"displayName" : @"JFIF",@"key" : @"{JFIF}",@"value" : self.jfif},
                          @{@"displayName" : @"MakerCanon",@"key" : @"{MakerCanon}",@"value" : self.makerCanon},
                          @{@"displayName" : @"MakerNikon",@"key" : @"{MakerNikon}",@"value" : self.makerNikon},
                          @{@"displayName" : @"PNG",@"key" : @"{PNG}",@"value" : self.png},
                          @{@"displayName" : @"TIFF",@"key" : @"{TIFF}",@"value" : self.tiff},
                          ];
}
@end
