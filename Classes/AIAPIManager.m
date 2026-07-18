//
//  AIAPIManager.m
//  Artificially Inteligent
//

#import "AIAPIManager.h"
#import "AICompat.h"
#import "AISettingsManager.h"
#import "AIProvider.h"
#import "AIOpenAIProvider.h"
#import "AIOllamaProvider.h"
#import "AIVoidAIProvider.h"
#import "AIGenericProvider.h"
#import <SystemConfiguration/SystemConfiguration.h>

// Delegate-based fallback connection object for pre-iOS 7 devices where
// NSURLSession does not exist. Accumulates data and reports back via block.
@interface AILegacyConnectionHandler : NSObject <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, copy) void (^completion)(NSData *data, NSURLResponse *response, NSError *error);
@property (nonatomic, strong) NSURLResponse *response;
@end

@implementation AILegacyConnectionHandler

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = response;
    self.receivedData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.completion) self.completion(nil, self.response, error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.completion) self.completion(self.receivedData, self.response, nil);
}

@end

@interface AIAPIManager ()
@property (nonatomic, strong) NSURLConnection *legacyConnection;
@property (nonatomic, strong) AILegacyConnectionHandler *legacyHandler;
@property (nonatomic, strong) id modernTask; // NSURLSessionDataTask, typed `id` to avoid a hard compile dependency
@end

@implementation AIAPIManager

+ (instancetype)sharedManager {
    static AIAPIManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AIAPIManager alloc] init];
    });
    return shared;
}

- (AIProvider *)currentProvider {
    AIProviderType type = [AISettingsManager sharedManager].activeProviderType;
    switch (type) {
        case AIProviderTypeOpenAICompatible: return [[AIOpenAIProvider alloc] init];
        case AIProviderTypeOllama:           return [[AIOllamaProvider alloc] init];
        case AIProviderTypeVoidAI:           return [[AIVoidAIProvider alloc] init];
        case AIProviderTypeCustom:           return [[AIGenericProvider alloc] init];
    }
    return [[AIOpenAIProvider alloc] init];
}

- (void)sendMessages:(NSArray *)history completion:(AISendCompletion)completion {
    if (![self isNetworkReachable]) {
        NSError *offlineError = [NSError errorWithDomain:@"AIAPIManager" code:100
                                                  userInfo:@{NSLocalizedDescriptionKey: @"No network connection detected."}];
        if (completion) completion(nil, offlineError);
        return;
    }

    AIProvider *provider = [self currentProvider];
    NSMutableURLRequest *request = [provider requestForMessages:history];
    if (!request) {
        NSError *configError = [NSError errorWithDomain:@"AIAPIManager" code:101
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Provider is not configured. Check API URL in Settings."}];
        if (completion) completion(nil, configError);
        return;
    }

    [self cancelCurrentRequest];

    void (^handleResult)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *networkError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (networkError) {
                if (completion) completion(nil, networkError);
                return;
            }

            NSInteger statusCode = 200;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                statusCode = ((NSHTTPURLResponse *)response).statusCode;
            }

            if (statusCode >= 400) {
                NSString *body = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
                NSError *httpError = [NSError errorWithDomain:@"AIAPIManager" code:statusCode
                                                       userInfo:@{NSLocalizedDescriptionKey:
                                                                      [NSString stringWithFormat:@"Server returned %ld: %@", (long)statusCode, body]}];
                if (completion) completion(nil, httpError);
                return;
            }

            NSError *parseError = nil;
            NSString *reply = [provider parseResponseData:data error:&parseError];
            if (!reply) {
                if (!parseError) {
                    parseError = [NSError errorWithDomain:@"AIAPIManager" code:102
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Could not parse a reply from the response."}];
                }
                if (completion) completion(nil, parseError);
                return;
            }

            if (completion) completion(reply, nil);
        });
    };

    if (AIHasNSURLSession()) {
        Class sessionClass = NSClassFromString(@"NSURLSession");
        Class configClass = NSClassFromString(@"NSURLSessionConfiguration");
        id configuration = configClass ? [configClass performSelector:@selector(defaultSessionConfiguration)] : nil;
        id session = [sessionClass performSelector:@selector(sessionWithConfiguration:) withObject:configuration];
        id task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            handleResult(data, response, error);
        }];
        [task resume];
        self.modernTask = task;
    } else {
        AILegacyConnectionHandler *handler = [[AILegacyConnectionHandler alloc] init];
        handler.completion = handleResult;
        self.legacyHandler = handler;
        self.legacyConnection = [[NSURLConnection alloc] initWithRequest:request delegate:handler startImmediately:YES];
    }
}

- (void)cancelCurrentRequest {
    if (self.modernTask && [self.modernTask respondsToSelector:@selector(cancel)]) {
        [self.modernTask performSelector:@selector(cancel)];
        self.modernTask = nil;
    }
    if (self.legacyConnection) {
        [self.legacyConnection cancel];
        self.legacyConnection = nil;
        self.legacyHandler = nil;
    }
}

- (BOOL)isNetworkReachable {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    if (!reachability) return YES; // fail open rather than blocking sends on a false negative

    SCNetworkReachabilityFlags flags;
    BOOL gotFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);

    if (!gotFlags) return YES;

    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL needsConnection = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    return isReachable && !needsConnection;
}

@end
