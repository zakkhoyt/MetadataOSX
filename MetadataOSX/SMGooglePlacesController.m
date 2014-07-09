//
//  SMGooglePlacesController.m
//  Radius_iOS
//
//  Created by Zakk Hoyt on 1/15/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "SMGooglePlacesController.h"


static NSString *SMGoogleAPIKey = @"AIzaSyCc6Ab9CdriC-IT53S_2qszNtrsCj2fSpQ";

@implementation SMGooglePlacesController


//-(void)queryGooglePlaces:(NSString *)googleType withCoordinate2D:(CLLocationCoordinate2D)currentCentre currentDist:(int)currentDist{
+(void)queryGooglePlacesWithLatitude:(double)latitude longitude:(double)longitude radius:(NSInteger)radius completion:(SMArrayBlock)completion{
//    Required parameters
//    
//    key — Your application's API key. This key identifies your application for purposes of quota management and so that Places added from your application are made immediately available to your app. Visit the APIs Console to create an API Project and obtain your key.
//    location — The latitude/longitude around which to retrieve Place information. This must be specified as latitude,longitude.
//    radius — Defines the distance (in meters) within which to return Place results. The maximum allowed radius is 50 000 meters. Note that radius must not be included if rankby=distance (described under Optional parameters below) is specified.
//    sensor — Indicates whether or not the Place request came from a device using a location sensor (e.g. a GPS) to determine the location sent in this request. This value must be either true or false.
//        
//        Optional parameters
//        
//    keyword — A term to be matched against all content that Google has indexed for this Place, including but not limited to name, type, and address, as well as customer reviews and other third-party content.
//    language — The language code, indicating in which language the results should be returned, if possible. See the list of supported languages and their codes. Note that we often update supported languages so this list may not be exhaustive.
//    minprice and maxprice (optional) — Restricts results to only those places within the specified range. Valid values range between 0 (most affordable) to 4 (most expensive), inclusive. The exact amount indicated by a specific value will vary from region to region.
//    name — One or more terms to be matched against the names of Places, separated with a space character. Results will be restricted to those containing the passed name values. Note that a Place may have additional names associated with it, beyond its listed name. The API will try to match the passed name value against all of these names; as a result, Places may be returned in the results whose listed names do not match the search term, but whose associated names do.
//    opennow — Returns only those Places that are open for business at the time the query is sent. Places that do not specify opening hours in the Google Places database will not be returned if you include this parameter in your query.
//    rankby — Specifies the order in which results are listed. Possible values are:
//    prominence (default). This option sorts results based on their importance. Ranking will favor prominent places within the specified area. Prominence can be affected by a Place's ranking in Google's index, the number of check-ins from your application, global popularity, and other factors.
//    distance. This option sorts results in ascending order by their distance from the specified location. Ranking results by distance will set a fixed search radius of 50km. One or more of keyword, name, or types is required.
//    types — Restricts the results to Places matching at least one of the specified types. Types should be separated with a pipe symbol (type1|type2|etc). See the list of supported types.
//    pagetoken — Returns the next 20 results from a previously run search. Setting a pagetoken parameter will execute a search with the same parameters used previously — all parameters other than pagetoken will be ignored.
//    zagatselected — Add this parameter (just the parameter name, with no associated value) to restrict your search to locations that are Zagat selected businesses. This parameter must not include a true or false value. The zagatselected parameter is experimental, and is only available to Places API enterprise customers.

    // Build the url string to send to Google. NOTE: The kGOOGLE_API_KEY is a constant that should contain your own API key that you obtain from Google. See this link for more info:
    // https://developers.google.com/maps/documentation/places/#Authentication
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%f,%f&radius=%@&sensor=true&key=%@", latitude, longitude, [NSString stringWithFormat:@"%ld", (long)radius], SMGoogleAPIKey];
    NSLog(@"request string: %@", urlString);
    
    //Formulate the string as a URL object.
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Retrieve the results of the URL.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:url];
        //[self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
        
        //parse out the json data
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&error];
        
        //The results from Google will be an array obtained from the NSDictionary object with the key "results".
        NSArray* places = [json objectForKey:@"results"];
        
//        //Write out the data to the console.
//        NSLog(@"Google Data: %@", places);

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(places);
        });

    });
}

@end
