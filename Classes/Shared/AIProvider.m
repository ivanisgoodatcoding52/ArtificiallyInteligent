//
//  AIProvider.m
//  Artificially Inteligent
//

#import "AIProvider.h"
#import "AISettingsManager.h"

@implementation AIProvider

- (NSString *)providerName {
    return @"Unknown Provider";
}

- (NSMutableURLRequest *)requestForMessages:(NSArray *)history {
    NSAssert(NO, @"AIProvider subclasses must override requestForMessages:");
    return nil;
}

- (NSString *)parseResponseData:(NSData *)data error:(NSError **)error {
    NSAssert(NO, @"AIProvider subclasses must override parseResponseData:error:");
    return nil;
}

- (NSTimeInterval)requestTimeoutInterval {
    NSTimeInterval configured = [[AISettingsManager sharedManager] requestTimeout];
    return configured > 0 ? configured : 30.0;
}

@end
