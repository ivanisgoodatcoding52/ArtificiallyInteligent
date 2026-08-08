//
//  AICompat.m
//  Artificially Inteligent (Modern / iOS 7+ tier)
//

#import "AICompat.h"
#import <objc/runtime.h>

BOOL AIIsIOS7OrLater(void) {
    return YES;
}

BOOL AIIsIOS8OrLater(void) {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0;
}

BOOL AIHasNSURLSession(void) {
    return YES;
}

BOOL AIHasNSJSONSerialization(void) {
    return YES;
}

BOOL AIIsArm64(void) {
#if defined(__LP64__) && __LP64__
    return YES;
#else
    return NO;
#endif
}

#pragma mark - iOS 7 UIActionSheet/UIAlertView delegate shim

// Only ever used on iOS 7 itself (see AIPresentConfirm below) - everything
// iOS 8+ goes through the real UIAlertController path further down.
@interface AILegacyDialogShim : NSObject <UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) AIConfirmHandler handler;
@property (nonatomic, assign) NSInteger confirmButtonIndex;
@end

@implementation AILegacyDialogShim

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.handler) self.handler(buttonIndex == self.confirmButtonIndex);
    objc_setAssociatedObject(actionSheet, "AIShimKey", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (self.handler) self.handler(buttonIndex == self.confirmButtonIndex);
    objc_setAssociatedObject(alertView, "AIShimKey", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

void AIPresentConfirm(UIViewController *presenter,
                       NSString *title,
                       NSString *message,
                       NSString *confirmTitle,
                       BOOL destructive,
                       AIConfirmHandler handler) {
    if (AIIsIOS8OrLater()) {
        // Real UIAlertController - this tier's SDK genuinely declares it,
        // so no dynamic dispatch needed, unlike the Legacy tier.
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        UIAlertActionStyle style = destructive ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction *action) {
            if (handler) handler(NO);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:confirmTitle
                                                    style:style
                                                  handler:^(UIAlertAction *action) {
            if (handler) handler(YES);
        }]];
        [presenter presentViewController:alert animated:YES completion:nil];
        return;
    }

    // iOS 7 only: UIAlertController doesn't exist yet.
    AILegacyDialogShim *shim = [[AILegacyDialogShim alloc] init];
    shim.handler = handler;

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:message
                                                         delegate:shim
                                                cancelButtonTitle:@"Cancel"
                                           destructiveButtonTitle:destructive ? confirmTitle : nil
                                                otherButtonTitles:destructive ? nil : confirmTitle, nil];
    shim.confirmButtonIndex = destructive ? sheet.destructiveButtonIndex : sheet.firstOtherButtonIndex;
    objc_setAssociatedObject(sheet, "AIShimKey", shim, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [sheet showInView:presenter.view];
}

void AIPresentAlert(UIViewController *presenter, NSString *title, NSString *message) {
    if (AIIsIOS8OrLater()) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                         message:message
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [presenter presentViewController:alert animated:YES completion:nil];
        return;
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    [alertView show];
}

CGFloat AIHeightForText(NSString *text, UIFont *font, CGFloat width) {
    if (!text.length) return 0;
    NSDictionary *attrs = @{ NSFontAttributeName: font };
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:attrs
                                      context:nil];
    return ceil(rect.size.height);
}
