//
//  AIPrefsRootListController.m
//  Artificially Inteligent Preferences
//

#import "AIPrefsRootListController.h"
#import <Preferences/PSSpecifier.h>

@implementation AIPrefsRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

// Bound to the "Clear Stored Data" button specifier in Root.plist via
// its "action" key (action = clearStoredData). Confirms before wiping
// NSUserDefaults + persisted conversation history.
- (void)clearStoredData {
    UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:@"Clear Stored Data"
                                                        message:@"This resets all Artificially Inteligent settings and deletes saved conversation history. This cannot be undone."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Clear", nil];
    confirm.tag = 1001;
    [confirm show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1001 && buttonIndex == 1) {
        // Reset the shared defaults suite the tweak reads from.
        // initWithSuiteName: is iOS7+ only and not declared in this
        // project's base SDK, so dispatch to it dynamically.
        NSUserDefaults *defaults = nil;
        SEL suiteInitSelector = @selector(initWithSuiteName:);
        if ([NSUserDefaults instancesRespondToSelector:suiteInitSelector]) {
            NSUserDefaults *allocated = [NSUserDefaults alloc];
            defaults = [allocated performSelector:suiteInitSelector withObject:@"com.yourname.artificiallyinteligent"];
        }
        defaults = defaults ?: [NSUserDefaults standardUserDefaults];

        NSDictionary *dict = [defaults dictionaryRepresentation];
        for (NSString *key in dict) {
            [defaults removeObjectForKey:key];
        }
        [defaults synchronize];

        // Delete the persisted conversation JSON if it exists.
        // firstObject isn't declared in this SDK either; count-checked
        // subscripting does the same job safely.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *base = (paths.count > 0) ? paths[0] : NSTemporaryDirectory();
        NSString *dir = [base stringByAppendingPathComponent:@"ArtificiallyInteligent"];
        [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];

        [self.tableView reloadData];
    }
}

@end
