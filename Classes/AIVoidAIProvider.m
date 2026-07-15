//
//  AIVoidAIProvider.m
//  Artificially Inteligent
//

#import "AIVoidAIProvider.h"
#import "AISettingsManager.h"
#import "AIJSONCompat.h"

static NSString * const kVoidAIDefaultBase = @"https://voidai.app/v1/chat/completions";

@implementation AIVoidAIProvider

- (NSString *)providerName {
    return @"VoidAI";
}

- (NSMutableURLRequest *)requestForMessages:(NSArray *)history {
    AISettingsManager *settings = [AISettingsManager sharedManager];

    NSString *urlString = settings.apiURL.length > 0 ? settings.apiURL : kVoidAIDefaultBase;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return nil;

    NSMutableArray *messages = [NSMutableArray array];
    if (settings.systemPrompt.length > 0) {
        [messages addObject:@{ @"role": @"system", @"content": settings.systemPrompt }];
    }
    [messages addObjectsFromArray:history];

    NSDictionary *body = @{
        @"model": settings.modelName.length > 0 ? settings.modelName : @"gpt-4o-mini",
        @"messages": messages,
        @"temperature": @(settings.temperature),
        @"max_tokens": @(settings.maxTokens),
        @"stream": @(settings.streamingEnabled)
    };

    NSError *jsonError = nil;
    NSData *bodyData = [AIJSONCompat dataWithJSONObject:body error:&jsonError];
    if (jsonError) return nil;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = [self requestTimeoutInterval];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (settings.apiKey.length > 0) {
        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", settings.apiKey];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    request.HTTPBody = bodyData;
    return request;
}

- (NSString *)parseResponseData:(NSData *)data error:(NSError **)error {
    // VoidAI mirrors the OpenAI chat completions response shape.
    id parsed = [AIJSONCompat JSONObjectWithData:data error:error];
    if (![parsed isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *dict = (NSDictionary *)parsed;

    if (dict[@"error"]) {
        NSString *msg = [dict[@"error"] isKindOfClass:[NSDictionary class]] ? dict[@"error"][@"message"] : dict[@"error"];
        if (error) {
            *error = [NSError errorWithDomain:@"AIVoidAIProvider" code:2
                                      userInfo:@{NSLocalizedDescriptionKey: msg ?: @"Unknown VoidAI error"}];
        }
        return nil;
    }

    NSArray *choices = dict[@"choices"];
    if (![choices isKindOfClass:[NSArray class]] || choices.count == 0) return nil;
    NSDictionary *message = choices[0][@"message"];
    return message[@"content"];
}

@end
