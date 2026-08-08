//
//  AICompat.h
//  Artificially Inteligent (Modern / iOS 7+ tier)
//
//  This is the iOS7+ counterpart to Classes/Legacy/AICompat.h. It exposes
//  the exact same public function signatures so the shared business-logic
//  files in Classes/Shared/ (AIJSONCompat.m, AIAPIManager.m) compile and
//  link identically regardless of which tier they're built into - only the
//  Makefile's header search path decides which AICompat.h wins.
//
//  Because this tier's floor is iOS 7.0 and it's built against a real iOS8+
//  SDK, almost everything here can just be a straight, un-shimmed call
//  instead of the legacy tier's NSClassFromString/performSelector dances.
//  The one exception is UIAlertController itself, which is iOS 8+ -- iOS 7
//  devices are still explicitly in scope for this tier, so that one still
//  needs a runtime fallback to UIActionSheet/UIAlertView.
//

#ifndef AICompat_h
#define AICompat_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Always YES on this tier (floor is iOS 7.0) - kept for API parity with the
// Legacy tier so shared call sites don't need to care which tier they're in.
BOOL AIIsIOS7OrLater(void);

// Real runtime check: UIAlertController is iOS 8+, and iOS 7 itself is
// still in scope for this tier's floor, so this one still matters.
BOOL AIIsIOS8OrLater(void);

// Always YES on this tier - NSURLSession has existed since iOS 7.0.
BOOL AIHasNSURLSession(void);

// Always YES on this tier - NSJSONSerialization has existed since iOS 5.0.
BOOL AIHasNSJSONSerialization(void);

BOOL AIIsArm64(void);

// Presents a two-button confirmation dialog: UIAlertController on iOS 8+,
// UIActionSheet on iOS 7 (the one OS version in this tier's range that
// doesn't have UIAlertController).
typedef void (^AIConfirmHandler)(BOOL confirmed);
void AIPresentConfirm(UIViewController *presenter,
                       NSString *title,
                       NSString *message,
                       NSString *confirmTitle,
                       BOOL destructive,
                       AIConfirmHandler handler);

void AIPresentAlert(UIViewController *presenter, NSString *title, NSString *message);

// Text height measurement via boundingRectWithSize:options:attributes:context:,
// unconditionally - safe on this tier's whole floor (iOS 6+ SDK feature).
CGFloat AIHeightForText(NSString *text, UIFont *font, CGFloat width);

#endif /* AICompat_h */
