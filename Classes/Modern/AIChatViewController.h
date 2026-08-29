//
//  AIChatViewController.h
//  Artificially Inteligent (Modern / iOS 7+ tier)
//
//  Main chat screen, redesigned for a genuine iOS 7+ flat aesthetic:
//  Auto Layout throughout, UIAlertController-based dialogs (via AICompat),
//  and message bubbles styled after the era's flat Messages.app look
//  rather than the legacy tier's manual-frame skeuomorphic-safe styling.
//

#import <UIKit/UIKit.h>

@interface AIChatViewController : UITableViewController

// Populates the input field with `text` and sends it immediately, exactly as
// if the user had typed it and tapped Send. Used by the standalone app's URL
// scheme handler (artificiallyinteligent://ask?text=...) so external callers
// can drive a real chat turn, not just open the screen.
- (void)sendPresetMessage:(NSString *)text;

@end
