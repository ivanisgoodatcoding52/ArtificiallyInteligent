//
//  AIPrefsRootListController.h
//  Artificially Inteligent Preferences
//
//  Standard PSListController subclass backing the Settings.app pane.
//  Root.plist declares the static items (pickers, text fields, switches);
//  this class only needs to handle the one dynamic action - "Clear Stored
//  Data" - that a plain plist specifier can't express on its own.
//

#import <Preferences/PSListController.h>

@interface AIPrefsRootListController : PSListController

- (void)clearStoredData;

@end
