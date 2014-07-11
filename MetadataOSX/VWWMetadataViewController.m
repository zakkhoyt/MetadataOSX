//
//  VWWMetadataViewController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/10/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWMetadataViewController.h"

@interface VWWMetadataViewController ()
@property (weak) IBOutlet NSPopUpButton *metadataPopup;
@property (unsafe_unretained) IBOutlet NSTextView *metadataTextView;

@end

@implementation VWWMetadataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Text View
    if(self.item.metadata){
        self.metadataTextView.string = self.item.metadata.description;
    }
    
    // Popup
    [self.metadataPopup removeAllItems];
    [self.metadataPopup addItemWithTitle:@"All"];
    
    NSDictionary *tiffDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyTIFFDictionary];
    if(tiffDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyTIFFDictionary];
    }
    
    NSDictionary *gifDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyGIFDictionary];
    if(gifDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyGIFDictionary];
    }
    
    NSDictionary *jfifDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyJFIFDictionary];
    if(jfifDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyJFIFDictionary];
    }
    
    NSDictionary *exifDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyExifDictionary];
    if(exifDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyExifDictionary];
    }
    
    NSDictionary *pngDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyPNGDictionary];
    if(pngDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyPNGDictionary];
    }
    
    NSDictionary *iptcDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyIPTCDictionary];
    if(iptcDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyIPTCDictionary];
    }
    
    NSDictionary *gpsDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyGPSDictionary];
    if(gpsDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyGPSDictionary];
    }
    
    NSDictionary *rawDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyRawDictionary];
    if(rawDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyRawDictionary];
    }
    
    NSDictionary *ciffDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyCIFFDictionary];
    if(ciffDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyCIFFDictionary];
    }
    
    NSDictionary *canonDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerCanonDictionary];
    if(canonDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerCanonDictionary];
    }
    
    NSDictionary *nikonDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerNikonDictionary];
    if(nikonDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerNikonDictionary];
    }
    
    NSDictionary *minoltaDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerMinoltaDictionary];
    if(minoltaDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerMinoltaDictionary];
    }
    
    NSDictionary *fujiDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerFujiDictionary];
    if(fujiDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerFujiDictionary];
    }
    
    NSDictionary *olumpusDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerOlympusDictionary];
    if(olumpusDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerOlympusDictionary];
    }
    
    NSDictionary *pentaxDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerPentaxDictionary];
    if(pentaxDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerPentaxDictionary];
    }
    
    NSDictionary *bim8Dictionary = [self.item.metadata valueForKey:(NSString*)kCGImageProperty8BIMDictionary];
    if(bim8Dictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImageProperty8BIMDictionary];
    }
    
    NSDictionary *dngDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyDNGDictionary];
    if(dngDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyDNGDictionary];
    }
    
    NSDictionary *exifAuxDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyExifAuxDictionary];
    if(exifAuxDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyExifAuxDictionary];
    }
    
    NSDictionary *openEXRDDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyOpenEXRDictionary];
    if(openEXRDDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyOpenEXRDictionary];
    }
    
    NSDictionary *appleDictionary = [self.item.metadata valueForKey:(NSString*)kCGImagePropertyMakerAppleDictionary];
    if(appleDictionary){
        [self.metadataPopup addItemWithTitle:(NSString*)kCGImagePropertyMakerAppleDictionary];
    }
    [self.metadataPopup selectItemAtIndex:0];
    
    
}

- (IBAction)metadataPopupAction:(NSPopUpButton *)sender {
    NSString *key = sender.selectedItem.title;
    NSLog(@"Key: %@", key);
    

    NSDictionary *dictionary = self.item.metadata[key];
    
    if([key rangeOfString:@"{"].location == 0){
        if(dictionary){
            self.metadataTextView.string = dictionary.description;
        } else {
            self.metadataTextView.string = @"Error";
        }
    } else if([key isEqualToString:@"All"]){
        self.metadataTextView.string = self.item.metadata.description;
    }
}

@end
