//
//  AIAppDelegate.h
//  Artificially Inteligent (standalone app)
//
//  Thin shell that presents the exact same AIChatViewController used by the
//  tweak's long-press overlay. Also handles the artificiallyinteligent://
//  URL scheme so other apps, Shortcuts, or a tapped link can drive a real
//  chat turn (not just open the screen) - see application:openURL: below.
//

#import <UIKit/UIKit.h>

@interface AIAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@end
