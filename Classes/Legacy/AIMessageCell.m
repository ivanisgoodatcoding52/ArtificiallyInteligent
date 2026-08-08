//
//  AIMessageCell.m
//  Artificially Inteligent
//

#import "AIMessageCell.h"
#import "AICompat.h"
#import <QuartzCore/QuartzCore.h>

NSString * const AIMessageCellReuseIdentifier = @"AIMessageCell";

static const CGFloat kBubblePaddingH = 12.0;
static const CGFloat kBubblePaddingV = 8.0;
static const CGFloat kBubbleMaxWidthRatio = 0.72;
static const CGFloat kBubbleSideMargin = 10.0;
static const CGFloat kBubbleVerticalMargin = 6.0;

@interface AIMessageCell ()
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, copy) NSString *rawContent;
@property (nonatomic, assign) BOOL isUserMessage;
@end

@implementation AIMessageCell

+ (UIFont *)bubbleFont {
    return [UIFont systemFontOfSize:16.0];
}

+ (CGFloat)heightForContent:(NSString *)content tableWidth:(CGFloat)tableWidth {
    CGFloat maxBubbleWidth = tableWidth * kBubbleMaxWidthRatio;
    CGFloat textWidth = maxBubbleWidth - (kBubblePaddingH * 2);
    CGFloat textHeight = AIHeightForText(content, [self bubbleFont], textWidth);
    return textHeight + (kBubblePaddingV * 2) + (kBubbleVerticalMargin * 2);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        _bubbleView = [[UIView alloc] init];
        _bubbleView.layer.cornerRadius = 14.0;
        _bubbleView.clipsToBounds = YES;
        [self.contentView addSubview:_bubbleView];

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.numberOfLines = 0;
        _contentLabel.font = [AIMessageCell bubbleFont];
        _contentLabel.backgroundColor = [UIColor clearColor];
        [_bubbleView addSubview:_contentLabel];
    }
    return self;
}

- (void)configureWithContent:(NSString *)content isUser:(BOOL)isUser {
    self.rawContent = content;
    self.isUserMessage = isUser;
    self.contentLabel.text = content;

    if (isUser) {
        // Blue bubble, white text - matches the familiar Messages.app "you" bubble
        // across every design era from iOS 3's glossier blue through iOS 7+'s flat blue.
        self.bubbleView.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
        self.contentLabel.textColor = [UIColor whiteColor];
    } else {
        self.bubbleView.backgroundColor = AIIsIOS7OrLater()
            ? [UIColor colorWithWhite:0.90 alpha:1.0]
            : [UIColor colorWithWhite:0.85 alpha:1.0];
        self.contentLabel.textColor = [UIColor blackColor];
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat tableWidth = CGRectGetWidth(self.contentView.bounds);
    CGFloat maxBubbleWidth = tableWidth * kBubbleMaxWidthRatio;
    CGFloat textWidth = maxBubbleWidth - (kBubblePaddingH * 2);
    CGFloat textHeight = AIHeightForText(self.rawContent, [AIMessageCell bubbleFont], textWidth);

    CGFloat bubbleWidth = textWidth + (kBubblePaddingH * 2);
    CGFloat bubbleHeight = textHeight + (kBubblePaddingV * 2);

    CGFloat bubbleX = self.isUserMessage
        ? (tableWidth - bubbleWidth - kBubbleSideMargin)
        : kBubbleSideMargin;

    self.bubbleView.frame = CGRectMake(bubbleX, kBubbleVerticalMargin, bubbleWidth, bubbleHeight);
    self.contentLabel.frame = CGRectMake(kBubblePaddingH, kBubblePaddingV, textWidth, textHeight);
}

#pragma mark - Copy support (long-press -> UIMenuController)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)copy:(id)sender {
    [UIPasteboard generalPasteboard].string = self.rawContent ?: @"";
}

@end
