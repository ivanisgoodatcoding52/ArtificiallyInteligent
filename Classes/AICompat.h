//
//  AICompat.h
//  Artificially Inteligent
//
//  Central place for legacy/modern iOS compatibility helpers.
//  Every class that needs to branch behavior by OS version, or safely probe
//  for a class/selector that may not exist on iOS 3-6, should go through here
//  instead of sprinkling raw NSClassFromString calls everywhere.
//

#ifndef AICompat_h
#define AICompat_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ---- OS version helpers ----------------------------------------------

// Returns YES on iOS 7.0 and later (flat UI, UIAlertController, etc.)
BOOL AIIsIOS7OrLater(void);

// Returns YES on iOS 8.0 and later (UIAlertController fully replaces UIActionSheet/UIAlertView)
BOOL AIIsIOS8OrLater(void);

// Returns YES if NSURLSession is available (iOS 7+) — otherwise callers
// should fall back to NSURLConnection.
BOOL AIHasNSURLSession(void);

// Returns YES if NSJSONSerialization is available (iOS 5+) — otherwise
// callers should fall back to AIJSONCompat's hand-rolled parser.
BOOL AIHasNSJSONSerialization(void);

// Returns YES if the device is 64-bit (arm64) — informs some layout choices.
BOOL AIIsArm64(void);

// ---- Safe UI helpers that behave correctly regardless of OS ----------

// Presents a simple two-button confirmation dialog, using UIAlertController
// on iOS 8+, and UIActionSheet on everything before that. `destructive`
// controls whether the confirm button is styled as destructive where possible.
typedef void (^AIConfirmHandler)(BOOL confirmed);
void AIPresentConfirm(UIViewController *presenter,
                       NSString *title,
                       NSString *message,
                       NSString *confirmTitle,
                       BOOL destructive,
                       AIConfirmHandler handler);

// Simple one-button alert (error display etc), same OS branching as above.
void AIPresentAlert(UIViewController *presenter, NSString *title, NSString *message);

// Computes the height needed to render `text` at `font` within `width`,
// using boundingRectWithSize: on iOS 7+ and sizeWithFont: before that.
CGFloat AIHeightForText(NSString *text, UIFont *font, CGFloat width);

#endif /* AICompat_h */
