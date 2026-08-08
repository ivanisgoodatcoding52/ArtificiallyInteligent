//
//  AIMessageCell.m
//  Artificially Inteligent (Modern / iOS 7+ tier)
//

#import "AIMessageCell.h"
#import "AICompat.h"
#import <QuartzCore/QuartzCore.h>

NSString * const AIMessageCellReuseIdentifier = @"AIMessageCell";

static const CGFloat kBubblePaddingH = 14.0;
static const CGFloat kBubblePaddingV = 10.0;
static const CGFloat kBubbleMaxWidthRatio = 0.72;
static const CGFloat kBubbleSideMargin = 12.0;
static const CGFloat kBubbleVerticalMargin = 5.0;

@interface AIMessageCell ()
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, copy) NSString *rawContent;

@property (nonatomic, strong) NSLayoutConstraint *bubbleLeadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleMaxWidthConstraint;
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
        _bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
        _bubbleView.layer.cornerRadius = 16.0;
        _bubbleView.layer.shadowColor = [UIColor blackColor].CGColor;
        _bubbleView.layer.shadowOpacity = 0.06;
        _bubbleView.layer.shadowOffset = CGSizeMake(0, 1);
        _bubbleView.layer.shadowRadius = 2.0;
        [self.contentView addSubview:_bubbleView];

        _contentLabel = [[UILabel alloc] init];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.numberOfLines = 0;
        _contentLabel.font = [AIMessageCell bubbleFont];
        _contentLabel.backgroundColor = [UIColor clearColor];
        [_bubbleView addSubview:_contentLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_bubbleView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kBubbleVerticalMargin],
            [_bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-kBubbleVerticalMargin],

            [_contentLabel.topAnchor constraintEqualToAnchor:_bubbleView.topAnchor constant:kBubblePaddingV],
            [_contentLabel.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-kBubblePaddingV],
            [_contentLabel.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor constant:kBubblePaddingH],
            [_contentLabel.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-kBubblePaddingH],
        ]];

        _bubbleMaxWidthConstraint = [_bubbleView.widthAnchor constraintLessThanOrEqualToAnchor:self.contentView.widthAnchor
                                                                                     multiplier:kBubbleMaxWidthRatio];
        _bubbleMaxWidthConstraint.active = YES;

        _bubbleLeadingConstraint = [_bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                                              constant:kBubbleSideMargin];
        _bubbleTrailingConstraint = [_bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                                                constant:-kBubbleSideMargin];
    }
    return self;
}

- (void)configureWithContent:(NSString *)content isUser:(BOOL)isUser {
    self.rawContent = content;
    self.contentLabel.text = content;

    if (isUser) {
        self.bubbleView.backgroundColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0];
        self.contentLabel.textColor = [UIColor whiteColor];
        self.bubbleLeadingConstraint.active = NO;
        self.bubbleTrailingConstraint.active = YES;
    } else {
        self.bubbleView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        self.contentLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        self.bubbleTrailingConstraint.active = NO;
        self.bubbleLeadingConstraint.active = YES;
    }
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
