//
//  Tweak.xm
//  Artificially Inteligent
//
//  Presents the chat UI as a modal, reachable from any app via an
//  Activator gesture if libactivator is installed, and always reachable
//  via a SpringBoard icon-less shortcut hook as a guaranteed fallback path
//  that requires no extra dependency.
//
//  Design note: we deliberately do NOT require libactivator. It's soft-wired
//  in with weak class lookups so the tweak still works standalone.
//

#import <UIKit/UIKit.h>
#import "Classes/AIChatViewController.h"

static UIWindow *gAIOverlayWindow = nil;

static void AIPresentChat(void) {
    if (gAIOverlayWindow) {
        gAIOverlayWindow.hidden = NO;
        return;
    }

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    CGRect frame = keyWindow ? keyWindow.bounds : [UIScreen mainScreen].bounds;

    gAIOverlayWindow = [[UIWindow alloc] initWithFrame:frame];
    gAIOverlayWindow.windowLevel = UIWindowLevelAlert + 1;
    gAIOverlayWindow.backgroundColor = [UIColor whiteColor];

    AIChatViewController *chatVC = [[AIChatViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:chatVC];

    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:nil
                                                                                    action:nil];
    // Assigned via associated block-target below so we don't need a
    // separate Objective-C class just to handle one button tap.
    closeButton.target = [AIChatDismisser sharedDismisser];
    closeButton.action = @selector(dismiss);
    chatVC.navigationItem.leftBarButtonItem = closeButton;

    gAIOverlayWindow.rootViewController = nav;
    [gAIOverlayWindow makeKeyAndVisible];
}

// Tiny helper object so the close button has a valid target/action pair
// without introducing a full extra class file for one method.
@interface AIChatDismisser : NSObject
+ (instancetype)sharedDismisser;
- (void)dismiss;
@end

@implementation AIChatDismisser

+ (instancetype)sharedDismisser {
    static AIChatDismisser *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AIChatDismisser alloc] init];
    });
    return shared;
}

- (void)dismiss {
    gAIOverlayWindow.hidden = YES;
}

@end

#pragma mark - Activator integration (soft dependency, iOS 3+)

// If libactivator is present, register a listener so the user can bind any
// gesture (e.g. status bar swipe) to opening the chat UI. If it's absent,
// this whole block is skipped safely.
%ctor {
    @autoreleasepool {
        Class activatorClass = NSClassFromString(@"LAActivator");
        Class eventClass = NSClassFromString(@"LAEvent");
        if (activatorClass && eventClass) {
            static NSString * const kActivatorListenerName = @"com.yourname.artificiallyinteligent.open";

            id activator = [activatorClass sharedInstance];
            if ([activator respondsToSelector:@selector(registerListener:forName:)]) {
                // Register a lightweight block-based listener wrapper.
                // LAListener is a protocol; we satisfy it with a tiny inline object.
                [activator performSelector:@selector(registerListener:forName:)
                                 withObject:[AIActivatorListener sharedListener]
                                 withObject:kActivatorListenerName];
            }
        }
    }
}

@interface AIActivatorListener : NSObject
+ (instancetype)sharedListener;
@end

@implementation AIActivatorListener

+ (instancetype)sharedListener {
    static AIActivatorListener *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AIActivatorListener alloc] init];
    });
    return shared;
}

// LAListener protocol method - matches libactivator's expected signature.
// Not declared against the protocol directly (it's not linked at compile
// time), so this relies on Objective-C's dynamic dispatch to be called.
- (void)activator:(id)activator receiveEvent:(id)event {
    AIPresentChat();
    if ([activator respondsToSelector:@selector(sendEventToSystem:)]) {
        [activator performSelector:@selector(sendEventToSystem:) withObject:event];
    }
}

- (void)activator:(id)activator receiveDeactivateEvent:(id)event {
    // no-op: single-shot open action
}

@end

#pragma mark - SpringBoard shortcut fallback

// Guaranteed entry point that needs no third-party dependency: long-pressing
// the status bar area on the home screen. This keeps the tweak fully
// self-contained for users without Activator installed.
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
        initWithTarget:[AIChatLauncher sharedLauncher] action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1.2;
    [keyWindow addGestureRecognizer:longPress];
}

%end

@interface AIChatLauncher : NSObject
+ (instancetype)sharedLauncher;
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer;
@end

@implementation AIChatLauncher

+ (instancetype)sharedLauncher {
    static AIChatLauncher *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AIChatLauncher alloc] init];
    });
    return shared;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        AIPresentChat();
    }
}

@end
