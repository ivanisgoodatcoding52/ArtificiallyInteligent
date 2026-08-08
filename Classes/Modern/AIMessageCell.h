//
//  AIMessageCell.h
//  Artificially Inteligent (Modern / iOS 7+ tier)
//
//  Auto Layout based chat bubble cell with a refreshed flat-era look:
//  refined padding, a subtle shadow on the bubble, and system-font
//  typography, in place of the Legacy tier's manual frame math.
//

#import <UIKit/UIKit.h>

extern NSString * const AIMessageCellReuseIdentifier;

@interface AIMessageCell : UITableViewCell

+ (CGFloat)heightForContent:(NSString *)content tableWidth:(CGFloat)tableWidth;

- (void)configureWithContent:(NSString *)content isUser:(BOOL)isUser;

@end
