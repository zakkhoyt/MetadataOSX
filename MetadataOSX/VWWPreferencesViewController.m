//
//  VWWPreferencesViewController.m
//  Throwback
//
//  Created by Zakk Hoyt on 7/11/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWPreferencesViewController.h"
#import "VWWUserDefaults.h"

@interface VWWPreferencesViewController ()
@property (weak) IBOutlet NSTextField *allowedTypesTextField;
@property (weak) IBOutlet NSMatrix *fileTypesMatrix;
@property (weak) IBOutlet NSMatrix *gpsMatrix;
@property (weak) IBOutlet NSMatrix *exifMatrix;


@end

@implementation VWWPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.allowedTypesTextField.stringValue = [VWWUserDefaults allowedTypes];
    
    [self.fileTypesMatrix selectCellAtRow:[VWWUserDefaults fileTypesRadio] column:0];
    [self.gpsMatrix selectCellAtRow:[VWWUserDefaults GPSRadio] column:0];
    [self.exifMatrix selectCellAtRow:[VWWUserDefaults EXIFRadio] column:0];
    
}
- (IBAction)fileMatrixAction:(NSMatrix *)sender {
    [VWWUserDefaults setFileTypesRadio:sender.selectedRow];
}
- (IBAction)allowedTypesTextFieldAction:(NSTextField *)sender {
    [VWWUserDefaults setAllowedTypes:sender.stringValue];
}

- (IBAction)gpsMatrixAction:(NSMatrix *)sender {
    [VWWUserDefaults setGPSRadio:sender.selectedRow];
}
- (IBAction)exifMatrixAction:(NSMatrix *)sender {
    [VWWUserDefaults setEXIFRadio:sender.selectedRow];
}


@end
