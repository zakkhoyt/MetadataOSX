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

@end

@implementation VWWPreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.allowedTypesTextField.stringValue = [VWWUserDefaults allowedTypes];
}

@end
