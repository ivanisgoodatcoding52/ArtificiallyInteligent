//
//  AIExternalBridge.m
//  Artificially Inteligent
//

#import "AIExternalBridge.h"
#import "AIJSONCompat.h"
#import "AIAPIManager.h"
#import <CoreFoundation/CoreFoundation.h>

static NSString * const kBridgeDefaultsSuite = @"com.rg.artificiallyinteligient";
static NSString * const kBridgeRequestKey = @"AIBridgePendingRequest";
static NSString * const kBridgeResponseKey = @"AIBridgeLastResponse";
static CFStringRef const kBridgeRequestNotification = CFSTR("com.rg.artificiallyinteligient.bridge.request");
static CFStringRef const kBridgeResponseNotification = CFSTR("com.rg.artificiallyinteligient.bridge.response");

// initWithSuiteName: is iOS7+ only and isn't declared in the older SDKs
// this project's armv6/armv7/a4a6 tiers build against (same issue fixed
// earlier in AISettingsManager.m) - dispatch to it dynamically rather than
// referencing it directly, which is a hard compile error on those SDKs.
static NSUserDefaults *AIBridgeSharedDefaults(void) {
    NSUserDefaults *defaults = nil;
    SEL suiteInitSelector = @selector(initWithSuiteName:);
    if ([NSUserDefaults instancesRespondToSelector:suiteInitSelector]) {
        NSUserDefaults *allocated = [NSUserDefaults alloc];
        defaults = [allocated performSelector:suiteInitSelector withObject:kBridgeDefaultsSuite];
    }
    return defaults ?: [NSUserDefaults standardUserDefaults];
}

static void AIBridgeHandleRequestNotification(CFNotificationCenterRef center,
                                               void *observer,
                                               CFStringRef name,
                                               const void *object,
                                               CFDictionaryRef userInfo) {
    NSUserDefaults *defaults = AIBridgeSharedDefaults();
    NSString *requestJSON = [defaults stringForKey:kBridgeRequestKey];
    if (requestJSON.length == 0) return;

    NSData *requestData = [requestJSON dataUsingEncoding:NSUTF8StringEncoding];
    id parsed = [AIJSONCompat JSONObjectWithData:requestData error:nil];
    if (![parsed isKindOfClass:[NSDictionary class]]) return;

    NSDictionary *request = (NSDictionary *)parsed;
    NSString *requestID = request[@"id"];
    NSString *text = request[@"text"];
    if (requestID.length == 0 || text.length == 0) return;

    NSArray *history = @[ @{ @"role": @"user", @"content": text } ];

    [[AIAPIManager sharedManager] sendMessages:history completion:^(NSString *replyText, NSError *error) {
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[@"id"] = requestID;
        if (error) {
            response[@"error"] = error.localizedDescription ?: @"Unknown error";
        } else {
            response[@"reply"] = replyText ?: @"";
        }

        NSData *responseData = [AIJSONCompat dataWithJSONObject:response error:nil];
        NSString *responseJSON = responseData ? [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] : nil;
        if (!responseJSON) return;

        NSUserDefaults *responseDefaults = AIBridgeSharedDefaults();
        [responseDefaults setObject:responseJSON forKey:kBridgeResponseKey];
        [responseDefaults synchronize];

        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                              kBridgeResponseNotification, NULL, NULL, true);
    }];
}

@implementation AIExternalBridge

+ (void)startListening {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                     NULL,
                                     AIBridgeHandleRequestNotification,
                                     kBridgeRequestNotification,
                                     NULL,
                                     CFNotificationSuspensionBehaviorDeliverImmediately);
}

@end
