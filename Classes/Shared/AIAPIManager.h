//
//  AIAPIManager.h
//  Artificially Inteligent
//
//  Single entry point the chat UI talks to. Owns the active AIProvider
//  (chosen per AISettingsManager.activeProviderType), performs the network
//  round-trip via NSURLSession where available and NSURLConnection
//  otherwise, and normalizes success/failure back to the caller.
//

#import <Foundation/Foundation.h>

typedef void (^AISendCompletion)(NSString *replyText, NSError *error);

@interface AIAPIManager : NSObject

+ (instancetype)sharedManager;

// Sends the full message history to whichever provider is currently active
// in settings. `history` is an ordered array of
// { @"role": @"user"/@"assistant", @"content": NSString }.
- (void)sendMessages:(NSArray *)history completion:(AISendCompletion)completion;

// Cancels any in-flight request (used when the user backs out or clears chat).
- (void)cancelCurrentRequest;

// Best-effort connectivity check used to short-circuit obviously offline sends.
- (BOOL)isNetworkReachable;

@end
