//
//  AIMessageCell.h
//  Artificially Inteligent
//
//  Manual-layout (no Auto Layout dependency) chat bubble cell. User
//  messages align right, assistant replies align left, matching the
//  Messages.app convention users already know from every era of iOS.
//

#import <UIKit/UIKit.h>

extern NSString * const AIMessageCellReuseIdentifier;

@interface AIMessageCell : UITableViewCell

+ (CGFloat)heightForContent:(NSString *)content tableWidth:(CGFloat)tableWidth;

- (void)configureWithContent:(NSString *)content isUser:(BOOL)isUser;

@end
