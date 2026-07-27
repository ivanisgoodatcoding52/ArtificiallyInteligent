//
//  AIConversationStore.m
//  Artificially Inteligent
//

#import "AIConversationStore.h"
#import "AISettingsManager.h"
#import "AIJSONCompat.h"

@interface AIConversationStore ()
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation AIConversationStore

+ (instancetype)sharedStore {
    static AIConversationStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AIConversationStore alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _messages = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)currentMessages {
    return [self.messages copy];
}

- (void)addMessageWithRole:(NSString *)role content:(NSString *)content {
    if (!role || !content) return;
    [self.messages addObject:@{
        @"role": role,
        @"content": content,
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    }];
    [self persist];
}

- (void)clearConversation {
    [self.messages removeAllObjects];
    [[NSFileManager defaultManager] removeItemAtPath:[self storagePath] error:nil];
}

- (NSString *)storageDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = (paths.count > 0) ? paths[0] : NSTemporaryDirectory();
    NSString *dir = [appSupport stringByAppendingPathComponent:@"ArtificiallyInteligent"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

- (NSString *)storagePath {
    return [[self storageDirectory] stringByAppendingPathComponent:@"conversation.json"];
}

- (void)loadPersistedConversation {
    if (![[AISettingsManager sharedManager] saveHistoryEnabled]) return;

    NSData *data = [NSData dataWithContentsOfFile:[self storagePath]];
    if (!data) return;

    id parsed = [AIJSONCompat JSONObjectWithData:data error:nil];
    if ([parsed isKindOfClass:[NSArray class]]) {
        self.messages = [NSMutableArray arrayWithArray:parsed];
    }
}

- (void)persist {
    if (![[AISettingsManager sharedManager] saveHistoryEnabled]) return;

    NSData *data = [AIJSONCompat dataWithJSONObject:self.messages error:nil];
    if (data) {
        [data writeToFile:[self storagePath] atomically:YES];
    }
}

- (NSString *)exportAsPlainText {
    NSMutableString *result = [NSMutableString string];
    for (NSDictionary *msg in self.messages) {
        NSString *role = [msg[@"role"] isEqualToString:@"user"] ? @"You" : @"Assistant";
        [result appendFormat:@"%@: %@\n\n", role, msg[@"content"]];
    }
    return result;
}

@end
