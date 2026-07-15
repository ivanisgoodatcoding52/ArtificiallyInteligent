//
//  AIGenericProvider.m
//  Artificially Inteligent
//

#import "AIGenericProvider.h"
#import "AISettingsManager.h"
#import "AIJSONCompat.h"

@implementation AIGenericProvider

- (NSString *)providerName {
    return [AISettingsManager sharedManager].genericProviderName ?: @"Custom Provider";
}

- (NSMutableURLRequest *)requestForMessages:(NSArray *)history {
    AISettingsManager *settings = [AISettingsManager sharedManager];

    NSURL *url = [NSURL URLWithString:settings.apiURL ?: @""];
    if (!url) return nil;

    NSString *lastUserMessage = @"";
    for (NSDictionary *msg in [history reverseObjectEnumerator]) {
        if ([msg[@"role"] isEqualToString:@"user"]) {
            lastUserMessage = msg[@"content"] ?: @"";
            break;
        }
    }

    NSString *template = settings.genericRequestTemplate;
    NSString *jsonBody;

    if (template.length > 0) {
        // User-authored template with simple placeholder substitution.
        jsonBody = [self substitutePlaceholdersInTemplate:template
                                                    message:lastUserMessage
                                                    history:history
                                                      model:settings.modelName
                                                     system:settings.systemPrompt];
    } else {
        // No template provided: fall back to a reasonable OpenAI-shaped default
        // so the provider is still usable out of the box.
        NSMutableArray *messages = [NSMutableArray array];
        if (settings.systemPrompt.length > 0) {
            [messages addObject:@{ @"role": @"system", @"content": settings.systemPrompt }];
        }
        [messages addObjectsFromArray:history];
        NSDictionary *body = @{
            @"model": settings.modelName ?: @"",
            @"messages": messages,
            @"temperature": @(settings.temperature)
        };
        NSData *data = [AIJSONCompat dataWithJSONObject:body error:nil];
        jsonBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = [self requestTimeoutInterval];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (settings.genericAuthHeaderName.length > 0 && settings.apiKey.length > 0) {
        NSString *format = settings.genericAuthHeaderFormat.length > 0 ? settings.genericAuthHeaderFormat : @"%@";
        NSString *value = [NSString stringWithFormat:format, settings.apiKey];
        [request setValue:value forHTTPHeaderField:settings.genericAuthHeaderName];
    }

    request.HTTPBody = [jsonBody dataUsingEncoding:NSUTF8StringEncoding];
    return request;
}

- (NSString *)substitutePlaceholdersInTemplate:(NSString *)template
                                        message:(NSString *)message
                                        history:(NSArray *)history
                                          model:(NSString *)model
                                         system:(NSString *)system {
    // Escape values destined for inside JSON string literals.
    NSString *(^jsonEscape)(NSString *) = ^NSString *(NSString *s) {
        NSMutableString *m = [NSMutableString stringWithString:s ?: @""];
        [m replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, m.length)];
        [m replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, m.length)];
        [m replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, m.length)];
        return m;
    };

    NSMutableString *result = [NSMutableString stringWithString:template];
    [result replaceOccurrencesOfString:@"{{message}}" withString:jsonEscape(message)
                                options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"{{model}}" withString:jsonEscape(model)
                                options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"{{system}}" withString:jsonEscape(system)
                                options:0 range:NSMakeRange(0, result.length)];

    if ([result rangeOfString:@"{{history}}"].location != NSNotFound) {
        NSData *historyData = [AIJSONCompat dataWithJSONObject:history error:nil];
        NSString *historyJSON = [[NSString alloc] initWithData:historyData encoding:NSUTF8StringEncoding] ?: @"[]";
        [result replaceOccurrencesOfString:@"{{history}}" withString:historyJSON
                                    options:0 range:NSMakeRange(0, result.length)];
    }

    return result;
}

- (NSString *)parseResponseData:(NSData *)data error:(NSError **)error {
    AISettingsManager *settings = [AISettingsManager sharedManager];
    id parsed = [AIJSONCompat JSONObjectWithData:data error:error];
    if (!parsed) return nil;

    NSString *path = settings.genericResponsePath.length > 0 ? settings.genericResponsePath : @"choices.0.message.content";
    id current = parsed;
    for (NSString *component in [path componentsSeparatedByString:@"."]) {
        if ([current isKindOfClass:[NSDictionary class]]) {
            current = current[component];
        } else if ([current isKindOfClass:[NSArray class]]) {
            NSInteger idx = [component integerValue];
            if (idx < 0 || idx >= (NSInteger)[(NSArray *)current count]) return nil;
            current = current[idx];
        } else {
            return nil;
        }
    }

    return [current isKindOfClass:[NSString class]] ? current : nil;
}

@end
