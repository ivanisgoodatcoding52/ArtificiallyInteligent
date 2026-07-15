//
//  AICompat.m
//  Artificially Inteligent
//

#import "AICompat.h"
#import <objc/runtime.h>

BOOL AIIsIOS7OrLater(void) {
    return floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1;
}

BOOL AIIsIOS8OrLater(void) {
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
    if (AIIsIOS8OrLater()) {
        Class alertControllerClass = NSClassFromString(@"UIAlertController");
        UIAlertController *alert = [alertControllerClass alertControllerWithTitle:title
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

    // iOS 3-7 fallback: UIActionSheet reads naturally as a confirm sheet.
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
    if (AIIsIOS8OrLater()) {
        Class alertControllerClass = NSClassFromString(@"UIAlertController");
        UIAlertController *alert = [alertControllerClass alertControllerWithTitle:title
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
