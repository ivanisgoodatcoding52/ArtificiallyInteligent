//
//  AIChatViewController.h
//  Artificially Inteligent
//
//  Main chat screen: UITableView-based message list, bottom input bar
//  that repositions with the keyboard, send/loading state, and toolbar
//  actions for clearing/exporting the conversation.
//

#import <UIKit/UIKit.h>

@interface AIChatViewController : UITableViewController

// Populates the input field with `text` and sends it immediately, exactly as
// if the user had typed it and tapped Send. Used by the standalone app's URL
// scheme handler (artificiallyinteligent://ask?text=...) so external callers
// can drive a real chat turn, not just open the screen.
- (void)sendPresetMessage:(NSString *)text;

@end
