//
//  AIOpenAIProvider.m
//  Artificially Inteligent
//

#import "AIOpenAIProvider.h"
#import "AISettingsManager.h"
#import "AIJSONCompat.h"

@implementation AIOpenAIProvider

- (NSString *)providerName {
    return @"OpenAI Compatible";
}

- (NSMutableURLRequest *)requestForMessages:(NSArray *)history {
    AISettingsManager *settings = [AISettingsManager sharedManager];

    NSString *base = settings.apiURL ?: @"";
    // Be forgiving: if the user only entered a base host, append the
    // conventional chat completions path.
    NSString *urlString = base;
    if (![base.lowercaseString containsString:@"/chat/completions"] &&
        ![base.lowercaseString containsString:@"/v1/"]) {
        if ([urlString hasSuffix:@"/"]) urlString = [urlString substringToIndex:urlString.length - 1];
        urlString = [urlString stringByAppendingString:@"/v1/chat/completions"];
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return nil;

    NSMutableArray *messages = [NSMutableArray array];
    if (settings.systemPrompt.length > 0) {
        [messages addObject:@{ @"role": @"system", @"content": settings.systemPrompt }];
    }
    [messages addObjectsFromArray:history];

    NSDictionary *body = @{
        @"model": settings.modelName ?: @"gpt-3.5-turbo",
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
    id parsed = [AIJSONCompat JSONObjectWithData:data error:error];
    if (![parsed isKindOfClass:[NSDictionary class]]) return nil;

    NSDictionary *dict = (NSDictionary *)parsed;

    // Standard error shape: {"error": {"message": "..."}}
    if (dict[@"error"]) {
        NSString *msg = dict[@"error"][@"message"] ?: @"Unknown API error";
        if (error) {
            *error = [NSError errorWithDomain:@"AIOpenAIProvider" code:2
                                      userInfo:@{NSLocalizedDescriptionKey: msg}];
        }
        return nil;
    }

    NSArray *choices = dict[@"choices"];
    if (![choices isKindOfClass:[NSArray class]] || choices.count == 0) return nil;

    NSDictionary *firstChoice = choices[0];
    NSDictionary *message = firstChoice[@"message"];
    NSString *content = message[@"content"];
    if (![content isKindOfClass:[NSString class]]) {
        // Some proxies use "text" instead of chat-style "message.content"
        content = firstChoice[@"text"];
    }
    return content;
}

@end
