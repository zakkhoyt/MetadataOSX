
#import "FileSystemItem.h"

@interface FileSystemItem (){
    NSString *relativePath;
    FileSystemItem *parent;
    NSMutableArray *children;
    NSString *rootPath;
}
@end

@implementation FileSystemItem

static FileSystemItem *rootItem = nil;


- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)obj {
    if (self = [super init]) {
        rootPath = path;
        relativePath = [[path lastPathComponent] copy];
        parent = obj;
    }
    return self;
}

+ (FileSystemItem *)rootItem {
//   if (rootItem == nil)
       rootItem = [[FileSystemItem alloc] initWithPath:@"/" parent:nil];
   return rootItem;       
}

+ (FileSystemItem *)rootItemWithPath:(NSString*)path {
//    if (rootItem == nil)
        rootItem = [[FileSystemItem alloc] initWithPath:path parent:nil];
    return rootItem;
}

- (NSArray *)children {
    if (children == NULL) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fullPath = [self fullPath];
        BOOL isDir, valid = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        if (valid && isDir) {
            NSArray *array = [fileManager contentsOfDirectoryAtPath:fullPath error:NULL];
            if (!array) {   // This is unexpected
                children = [[NSMutableArray alloc] init];
            } else {
                NSInteger cnt, numChildren = [array count];
                children = [[NSMutableArray alloc] initWithCapacity:numChildren];
                for (cnt = 0; cnt < numChildren; cnt++) {
                    FileSystemItem *item = [[FileSystemItem alloc] initWithPath:[array objectAtIndex:cnt] parent:self];
                    [children addObject:item];
                }
            }
        } else {
            children = nil;
        }
    }
    return children;
}

- (NSString *)relativePath {
    return relativePath;
}

- (NSString *)fullPath {
    return parent ? [[parent fullPath] stringByAppendingPathComponent:relativePath] : rootPath;
}

- (FileSystemItem *)childAtIndex:(NSInteger)n {
    return [[self children] objectAtIndex:n];
}


- (NSInteger)numberOfChildren {
    return [self children] ? self.children.count : -1;
}

-(void)setMetadata:(NSMutableDictionary *)metadata{
    @synchronized(self){
        _metadata = metadata;
    }
}


-(void)setAnnotationCoordinate:(CLLocationCoordinate2D)coordinate{
    _coordinate = coordinate;
}

@end


