

#import <Foundation/Foundation.h>

@interface FileSystemItem : NSObject 
+ (FileSystemItem *)rootItemWithPath:(NSString*)path;
+ (FileSystemItem *)rootItem;
- (NSInteger)numberOfChildren;			// Returns -1 for leaf nodes
- (FileSystemItem *)childAtIndex:(NSInteger)n;	// Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;
@end
