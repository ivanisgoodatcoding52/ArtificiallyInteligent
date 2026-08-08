//
//  AIPrefsRootListController.h
//  Artificially Inteligent Preferences
//
//  Standard PSListController subclass backing the Settings.app pane.
//  Root.plist declares the static items (pickers, text fields, switches);
//  this class only needs to handle the one dynamic action - "Clear Stored
//  Data" - that a plain plist specifier can't express on its own.
//

// Theos' vendored Preferences.framework headers (PSTableCell.h,
// PSSpecifier.h) use the modern clang availability macro API_AVAILABLE(...)
// on a few methods. Against this project's old deployment target it doesn't
// expand the way those headers expect, and the parser chokes on it as if it
// were part of the method signature ("expected ';' after method prototype").
// We don't need the actual availability annotation for our usage, so
// neutralizing it to a no-op here -- before those headers are included --
// sidesteps the parse failure entirely.
#ifdef API_AVAILABLE
#undef API_AVAILABLE
#endif
#define API_AVAILABLE(...)

#import <Preferences/PSListController.h>

@interface AIPrefsRootListController : PSListController

- (void)clearStoredData;

@end
