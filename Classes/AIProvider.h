//
//  AIProvider.h
//  Artificially Inteligent
//
//  Abstract base for all AI backend providers. Concrete subclasses
//  (AIOpenAIProvider, AIOllamaProvider, AIVoidAIProvider, AIGenericProvider)
//  turn conversation history into a request and turn raw response bytes
//  back into plain reply text.
//

#import <Foundation/Foundation.h>

@interface AIProvider : NSObject

// Human readable name shown in Settings, e.g. "OpenAI Compatible".
@property (nonatomic, copy, readonly) NSString *providerName;

// Builds the outgoing request for a full message history.
// `history` is an array of NSDictionary: { @"role": @"user"/@"assistant"/@"system", @"content": NSString }
// Subclasses MUST override. The base implementation raises.
- (NSMutableURLRequest *)requestForMessages:(NSArray *)history;

// Parses a completed response body into plain reply text.
// Subclasses MUST override. The base implementation raises.
- (NSString *)parseResponseData:(NSData *)data error:(NSError **)error;

// Convenience used by AIAPIManager to know how long to wait before giving up.
// Providers can override; default comes from AISettingsManager's timeout setting.
- (NSTimeInterval)requestTimeoutInterval;

@end
