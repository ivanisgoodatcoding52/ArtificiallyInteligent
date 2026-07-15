//
//  AIOllamaProvider.m
//  Artificially Inteligent
//

#import "AIOllamaProvider.h"
#import "AISettingsManager.h"
#import "AIJSONCompat.h"

@implementation AIOllamaProvider

- (NSString *)providerName {
    return @"Ollama";
}

- (NSMutableURLRequest *)requestForMessages:(NSArray *)history {
    AISettingsManager *settings = [AISettingsManager sharedManager];

    NSString *base = settings.apiURL ?: @"";
    if ([base hasSuffix:@"/"]) base = [base substringToIndex:base.length - 1];
    // Use /api/chat so multi-turn history is preserved server-side; this is
    // the modern Ollama endpoint and works the same on LAN servers.
    NSString *urlString = [base stringByAppendingString:@"/api/chat"];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return nil;

    NSMutableArray *messages = [NSMutableArray array];
    if (settings.systemPrompt.length > 0) {
        [messages addObject:@{ @"role": @"system", @"content": settings.systemPrompt }];
    }
    [messages addObjectsFromArray:history];

    NSDictionary *options = @{
        @"temperature": @(settings.temperature),
        @"num_ctx": @(settings.ollamaContextLength)
    };

    NSDictionary *body = @{
        @"model": settings.modelName ?: @"llama2",
        @"messages": messages,
        @"options": options,
        // Non-streaming by default: simpler to parse and far friendlier to
        // devices like the iPhone 3GS. Streaming path lives in AIAPIManager
        // for devices/settings where it's explicitly enabled.
        @"stream": @(settings.streamingEnabled)
    };

    NSError *jsonError = nil;
    NSData *bodyData = [AIJSONCompat dataWithJSONObject:body error:&jsonError];
    if (jsonError) return nil;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = [self requestTimeoutInterval];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = bodyData;
    return request;
}

- (NSString *)parseResponseData:(NSData *)data error:(NSError **)error {
    // Non-streaming Ollama responses are a single JSON object.
    // Streaming responses are newline-delimited JSON objects; if streaming
    // was on, AIAPIManager hands us only the final accumulated buffer, so
    // we just parse the last line here as a safety net.
    NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *lines = [raw componentsSeparatedByString:@"\n"];
    NSString *lastNonEmptyLine = nil;
    for (NSString *line in lines) {
        if (line.length > 0) lastNonEmptyLine = line;
    }
    NSData *finalData = lastNonEmptyLine ? [lastNonEmptyLine dataUsingEncoding:NSUTF8StringEncoding] : data;

    id parsed = [AIJSONCompat JSONObjectWithData:finalData error:error];
    if (![parsed isKindOfClass:[NSDictionary class]]) return nil;

    NSDictionary *dict = (NSDictionary *)parsed;
    if (dict[@"error"]) {
        if (error) {
            *error = [NSError errorWithDomain:@"AIOllamaProvider" code:2
                                      userInfo:@{NSLocalizedDescriptionKey: dict[@"error"]}];
        }
        return nil;
    }

    NSDictionary *message = dict[@"message"];
    NSString *content = message[@"content"];
    return content;
}

@end
