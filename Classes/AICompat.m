//
//  AICompat.m
//  Artificially Inteligent
//

#import "AICompat.h"
#import <objc/runtime.h>

BOOL AIIsIOS7OrLater(void) {
    // Avoid NSFoundationVersionNumber_iOS_* constants entirely: some
    // repackaged/community Theos SDKs don't define every point-release
    // constant (e.g. _iOS_6_1 may be missing even though the SDK itself is
    // 6.1), which is a hard compile error rather than a runtime issue.
    // Comparing the live systemVersion string is portable across every SDK.
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
}

BOOL AIIsIOS8OrLater(void) {
    // Safe to call regardless of base SDK: NSClassFromString always exists
    // in Foundation, and comparing the returned Class to nil never requires
    // the class itself to be declared at compile time.
    return NSClassFromString(@"UIAlertController") != nil;
}

BOOL AIHasNSURLSession(void) {
    return NSClassFromString(@"NSURLSession") != nil;
}

BOOL AIHasNSJSONSerialization(void) {
    return NSClassFromString(@"NSJSONSerialization") != nil;
}

BOOL AIIsArm64(void) {
#if defined(__LP64__) && __LP64__
    return YES;
#else
    return NO;
#endif
}

#pragma mark - Legacy delegate shim

// UIActionSheet/UIAlertView (pre-iOS 8) are delegate-based, not block-based.
// This tiny object bridges them to a block so call sites can stay uniform.
@interface AILegacyDialogShim : NSObject <UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) AIConfirmHandler handler;
@property (nonatomic, assign) NSInteger confirmButtonIndex;
@end

@implementation AILegacyDialogShim

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.handler) {
        self.handler(buttonIndex == self.confirmButtonIndex);
    }
    objc_setAssociatedObject(actionSheet, "AIShimKey", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.handler) {
        self.handler(buttonIndex == self.confirmButtonIndex);
    }
    objc_setAssociatedObject(alertView, "AIShimKey", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

void AIPresentConfirm(UIViewController *presenter,
                       NSString *title,
                       NSString *message,
                       NSString *confirmTitle,
                       BOOL destructive,
                       AIConfirmHandler handler) {
    // UIActionSheet is deprecated starting iOS 8 but remains fully functional
    // through iOS 10 (the newest OS this tweak targets), and its class is
    // declared in every SDK back to iOS 2. Using it universally avoids
    // depending on UIAlertController/UIAlertAction, which this project's
    // base SDK (as old as ~6.1 for the armv6/armv7 slices) does not declare
    // at all -- referencing those types directly is a hard compile error
    // here, not just a deprecation warning.
    AILegacyDialogShim *shim = [[AILegacyDialogShim alloc] init];
    shim.handler = handler;

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:message
                                                         delegate:shim
                                                cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:destructive ? confirmTitle : nil
                                                otherButtonTitles:destructive ? nil : confirmTitle, nil];
    shim.confirmButtonIndex = destructive ? sheet.destructiveButtonIndex : sheet.firstOtherButtonIndex;

    // Keep the shim alive for the lifetime of the sheet.
    objc_setAssociatedObject(sheet, "AIShimKey", shim, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [sheet showInView:presenter.view];
}

void AIPresentAlert(UIViewController *presenter, NSString *title, NSString *message) {
    // Same reasoning as AIPresentConfirm above: UIAlertView universally,
    // no UIAlertController branch.
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    [alertView show];
}

CGFloat AIHeightForText(NSString *text, UIFont *font, CGFloat width) {
    if (!text.length) return 0;

    if (AIIsIOS7OrLater()) {
        NSDictionary *attrs = @{ NSFontAttributeName: font };
        CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attrs
                                          context:nil];
        return ceil(rect.size.height);
    }

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    CGSize size = [text sizeWithFont:font
                    constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                        lineBreakMode:NSLineBreakByWordWrapping];
    return ceil(size.height);
#else
    return 0;
#endif
}
