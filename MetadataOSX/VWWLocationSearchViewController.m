//
//  VWWLocationSearchController.m
//  MetadataOSX
//
//  Created by Zakk Hoyt on 7/9/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWLocationSearchViewController.h"
@import MapKit;

typedef void (^VWWMKLocalSearchResponseBlock)(MKLocalSearchResponse *response);

@interface VWWLocationSearchViewController ()
@property (weak) IBOutlet NSSearchField *searchBar;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) NSArray *places;
@property (weak) IBOutlet MKMapView *mapView;
@end

@implementation VWWLocationSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self.tableView setAction:@selector(tableViewAction:)];
    [self.tableView setDoubleAction:@selector(tableViewDoubleAction:)];
}
-(void)viewWillAppear{
    [super viewWillAppear];
    self.view.window.title = @"Search for Location";
    if(self.region.center.latitude == 0 && self.region.center.longitude == 0){
        self.mapView.centerCoordinate = self.mapView.userLocation.coordinate;
    } else {
        self.mapView.region = self.region;
    }
}




-(void)locationsFromAddress:(NSString*)addressString  completionBlock:(VWWMKLocalSearchResponseBlock)completionBlock{
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.region = self.mapView.region;
    request.naturalLanguageQuery = addressString;
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        return completionBlock(response);
    }];
}

- (IBAction)searchFieldAction:(NSSearchField *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self locationsFromAddress:sender.stringValue completionBlock:^(MKLocalSearchResponse *response) {
        if(response){
            self.places = [response.mapItems copy];
            [self.tableView reloadData];
        }
    }];
}

- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewController:self];
}

-(void)tableViewAction:(id)sender{
    NSInteger index = self.tableView.selectedRow;
    if(index != -1){
        MKMapItem *item = self.places[index];
        MKPlacemark *placemark = item.placemark;
        //[self.mapView setCenterCoordinate:placemark.coordinate animated:YES];
        [self.mapView setRegion:MKCoordinateRegionMake(placemark.coordinate, MKCoordinateSpanMake(0.05, 0.05)) animated:YES];
        
        // If user clicked with option key pressed, show details
        NSUInteger flags = [[NSApp currentEvent] modifierFlags];
        if ((flags & NSAlternateKeyMask)) {
            NSAlert *alert = [[NSAlert alloc]init];
            alert.messageText = placemark.description;
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            }];
        }
    }
}


-(void)tableViewDoubleAction:(id)sender{
    NSInteger index = self.tableView.selectedRow;
    if(index != -1){
        MKMapItem *item = self.places[index];
        MKPlacemark *placemark = item.placemark;
        [self.delegate reportVWWMainViewController:self coordinate:placemark.coordinate];
    }
    
    [self dismissViewController:self];
}



#pragma mark Implements NSTableViewDataSource
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if([tableColumn.identifier isEqualToString:@"location"]){

        MKMapItem *item = self.places[row];
        MKPlacemark *placemark = item.placemark;
        
        
        NSMutableString *textString = [[NSMutableString alloc]init];
        if(placemark.name){
            textString = [placemark.name mutableCopy];
        }
        
        if(placemark.subLocality && placemark.locality){
            [textString appendFormat:@" %@", [NSString stringWithFormat:@"%@ %@", placemark.subLocality, placemark.locality]];
        } else if(placemark.locality){
            [textString appendFormat:@" %@", placemark.locality];
        } else if(placemark.subLocality){
            [textString appendFormat:@" %@", placemark.subLocality];
        } else if(placemark.name){
            [textString appendFormat:@" %@", placemark.name];
        }
        cellView.textField.stringValue = textString;
        
        
//        NSString *detailTextString;
//        if(placemark.subThoroughfare && placemark.thoroughfare){
//            detailTextString = [NSString stringWithFormat:@"%@ %@", placemark.subThoroughfare, placemark.thoroughfare];
//        } else if(placemark.subThoroughfare){
//            detailTextString = placemark.subThoroughfare;
//        } else if(placemark.thoroughfare){
//            detailTextString = placemark.thoroughfare;
//        } else if(placemark.subAdministrativeArea){
//            detailTextString = placemark.subAdministrativeArea;
//        } else {
//            detailTextString = @"";
//        }
//        
//        
//        
//        cellView.textField.stringValue = detailTextString;
        return cellView;
    }

    cellView.textField.stringValue = @"";
    return cellView;
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.places.count;
}





@end
