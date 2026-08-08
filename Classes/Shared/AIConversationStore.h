//
//  AIConversationStore.h
//  Artificially Inteligent
//
//  Persists conversation history to disk as small JSON files rather than
//  SQLite/CoreData - chat volume on a personal legacy device is low enough
//  that a flat-file store is simpler and lighter on RAM/CPU than owning a
//  database stack.
//

#import <Foundation/Foundation.h>

@interface AIConversationStore : NSObject

+ (instancetype)sharedStore;

// Each message: { @"role": @"user"/@"assistant", @"content": NSString, @"timestamp": NSNumber }
@property (nonatomic, strong, readonly) NSArray *currentMessages;

- (void)addMessageWithRole:(NSString *)role content:(NSString *)content;
- (void)clearConversation;

// Loads whatever was last saved to disk (only relevant if the
// "save history" setting was on when the app was last used).
- (void)loadPersistedConversation;

// Persists `currentMessages` to disk immediately. No-ops if the
// "save history" setting is off.
- (void)persist;

// Returns a plain-text rendering suitable for the share sheet / export.
- (NSString *)exportAsPlainText;

@end
