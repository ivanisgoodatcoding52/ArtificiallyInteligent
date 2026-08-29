//
//  AIAppDelegate.m
//  Artificially Inteligent (standalone app)
//

#import "AIAppDelegate.h"
#import "AIChatViewController.h"

@interface AIAppDelegate ()
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) AIChatViewController *chatViewController;
@end

@implementation AIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    self.chatViewController = [[AIChatViewController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.chatViewController];

    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];

    NSURL *launchURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    if (launchURL) {
        [self handleIncomingURL:launchURL];
    }

    return YES;
}

// Pre-iOS9 delegate method, kept deliberately instead of the newer
// application:openURL:options: - this one has worked unchanged since the
// very first URL-scheme-capable iOS releases and stays correct across every
// tier this app builds for.
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [self handleIncomingURL:url];
}

- (BOOL)handleIncomingURL:(NSURL *)url {
    // Expected form: artificiallyinteligent://ask?text=<url-encoded message>
    if (!url) return NO;

    NSString *query = url.query;
    if (query.length == 0) return NO;

    NSString *text = [self valueForQueryKey:@"text" inQueryString:query];
    if (text.length == 0) return NO;

    [self.chatViewController sendPresetMessage:text];
    return YES;
}

// Manual query-string parsing instead of NSURLComponents/NSURLQueryItem
// (both iOS 7/8+ only) - this app builds all the way down to the a4a6/armv7
// tiers' iOS 4-5 floor, so sticking to NSString APIs that have existed since
// the earliest iOS SDKs keeps this correct everywhere it's linked.
- (NSString *)valueForQueryKey:(NSString *)key inQueryString:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSRange equalsRange = [pair rangeOfString:@"="];
        if (equalsRange.location == NSNotFound) continue;

        NSString *pairKey = [pair substringToIndex:equalsRange.location];
        if (![pairKey isEqualToString:key]) continue;

        NSString *rawValue = [pair substringFromIndex:equalsRange.location + 1];
        NSString *decoded = [rawValue stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        decoded = [decoded stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        return decoded;
    }
    return nil;
}

@end
