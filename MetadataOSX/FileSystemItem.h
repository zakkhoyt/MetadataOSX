

#import <Foundation/Foundation.h>
@import MapKit;

@interface FileSystemItem : NSObject <MKAnnotation>

+ (FileSystemItem *)rootItemWithPath:(NSString*)path;
+ (FileSystemItem *)rootItem;
- (NSInteger)numberOfChildren;			// Returns -1 for leaf nodes
- (FileSystemItem *)childAtIndex:(NSInteger)n;	// Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;
@property (nonatomic, strong) NSMutableDictionary *metadata;

// MKAnnotation
-(void)setAnnotationCoordinate:(CLLocationCoordinate2D)coordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@end
