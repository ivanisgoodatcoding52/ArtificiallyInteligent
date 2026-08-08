//
//  AIChatViewController.m
//  Artificially Inteligent (Modern / iOS 7+ tier)
//

#import "AIChatViewController.h"
#import "AIMessageCell.h"
#import "AIAPIManager.h"
#import "AIConversationStore.h"
#import "AISettingsManager.h"
#import "AICompat.h"

static NSString * const kLoadingCellIdentifier = @"AILoadingCell";

@interface AIChatViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *inputContainer;
@property (nonatomic, strong) UIView *inputSeparator;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSLayoutConstraint *inputBottomConstraint;

@property (nonatomic, assign) BOOL isWaitingForReply;

@end

@implementation AIChatViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Artificially Inteligent";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.allowsSelection = NO;

    [self setupNavigationBar];
    [self setupInputBar];
    [self registerForKeyboardNotifications];

    [[AIConversationStore sharedStore] loadPersistedConversation];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Nav bar

- (void)setupNavigationBar {
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                          style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(clearButtonTapped)];
}

- (void)clearButtonTapped {
    AIPresentConfirm(self, @"Clear Conversation", @"This removes all messages in this chat. This cannot be undone.",
                      @"Clear", YES, ^(BOOL confirmed) {
        if (confirmed) {
            [[AIConversationStore sharedStore] clearConversation];
            [self.tableView reloadData];
        }
    });
}

#pragma mark - Input bar (Auto Layout)

- (void)setupInputBar {
    self.inputContainer = [[UIView alloc] init];
    self.inputContainer.backgroundColor = [UIColor whiteColor];
    self.inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.inputContainer];

    // Flat hairline separator, in place of the legacy tier's UIToolbar chrome.
    self.inputSeparator = [[UIView alloc] init];
    self.inputSeparator.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    self.inputSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputContainer addSubview:self.inputSeparator];

    self.inputField = [[UITextField alloc] init];
    self.inputField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputField.placeholder = @"Message";
    self.inputField.delegate = self;
    self.inputField.returnKeyType = UIReturnKeySend;
    self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputContainer addSubview:self.inputField];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputContainer addSubview:self.sendButton];
    [self.sendButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.sendButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    self.inputBottomConstraint = [self.inputContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [self.inputContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.inputBottomConstraint,
        [self.inputContainer.heightAnchor constraintEqualToConstant:52],

        [self.inputSeparator.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor],
        [self.inputSeparator.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor],
        [self.inputSeparator.topAnchor constraintEqualToAnchor:self.inputContainer.topAnchor],
        [self.inputSeparator.heightAnchor constraintEqualToConstant:0.5],

        [self.inputField.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:12],
        [self.inputField.centerYAnchor constraintEqualToAnchor:self.inputContainer.centerYAnchor],
        [self.inputField.heightAnchor constraintEqualToConstant:34],
        [self.inputField.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-8],

        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-12],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.inputContainer.centerYAnchor],
    ]];

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 52, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(keyboardWillShow:)
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(keyboardWillHide:)
                                                  name:UIKeyboardWillHideNotification
                                                object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;

    self.inputBottomConstraint.constant = -keyboardHeight;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight + 52, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self scrollToBottomAnimated:YES];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    self.inputBottomConstraint.constant = 0;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 52, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;

    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonTapped];
    return YES;
}

#pragma mark - Sending

- (void)sendButtonTapped {
    NSString *text = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0 || self.isWaitingForReply) return;

    self.inputField.text = @"";
    [[AIConversationStore sharedStore] addMessageWithRole:@"user" content:text];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];

    self.isWaitingForReply = YES;
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];

    NSArray *history = [self apiFormattedHistory];
    __weak typeof(self) weakSelf = self;
    [[AIAPIManager sharedManager] sendMessages:history completion:^(NSString *replyText, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        strongSelf.isWaitingForReply = NO;

        if (error) {
            [strongSelf.tableView reloadData];
            AIPresentAlert(strongSelf, @"Request Failed", error.localizedDescription);
            return;
        }

        [[AIConversationStore sharedStore] addMessageWithRole:@"assistant" content:replyText ?: @""];
        [strongSelf.tableView reloadData];
        [strongSelf scrollToBottomAnimated:YES];
    }];
}

- (NSArray *)apiFormattedHistory {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *msg in [AIConversationStore sharedStore].currentMessages) {
        [result addObject:@{ @"role": msg[@"role"], @"content": msg[@"content"] }];
    }
    return result;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    if (rows == 0) return;
    NSIndexPath *last = [NSIndexPath indexPathForRow:rows - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger messageCount = [AIConversationStore sharedStore].currentMessages.count;
    return messageCount + (self.isWaitingForReply ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *messages = [AIConversationStore sharedStore].currentMessages;

    if (indexPath.row >= (NSInteger)messages.count) {
        UITableViewCell *loadingCell = [tableView dequeueReusableCellWithIdentifier:kLoadingCellIdentifier];
        if (!loadingCell) {
            loadingCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLoadingCellIdentifier];
            loadingCell.selectionStyle = UITableViewCellSelectionStyleNone;
            loadingCell.backgroundColor = [UIColor clearColor];
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.tag = 999;
            spinner.translatesAutoresizingMaskIntoConstraints = NO;
            [loadingCell.contentView addSubview:spinner];
            [NSLayoutConstraint activateConstraints:@[
                [spinner.leadingAnchor constraintEqualToAnchor:loadingCell.contentView.leadingAnchor constant:16],
                [spinner.centerYAnchor constraintEqualToAnchor:loadingCell.contentView.centerYAnchor],
            ]];
        }
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[loadingCell.contentView viewWithTag:999];
        [spinner startAnimating];
        return loadingCell;
    }

    NSDictionary *message = messages[indexPath.row];
    AIMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:AIMessageCellReuseIdentifier];
    if (!cell) {
        cell = [[AIMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AIMessageCellReuseIdentifier];
    }
    BOOL isUser = [message[@"role"] isEqualToString:@"user"];
    [cell configureWithContent:message[@"content"] isUser:isUser];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *messages = [AIConversationStore sharedStore].currentMessages;
    if (indexPath.row >= (NSInteger)messages.count) {
        return 40.0;
    }
    NSDictionary *message = messages[indexPath.row];
    return [AIMessageCell heightForContent:message[@"content"] tableWidth:CGRectGetWidth(tableView.bounds)];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row < (NSInteger)[AIConversationStore sharedStore].currentMessages.count;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        NSDictionary *message = [AIConversationStore sharedStore].currentMessages[indexPath.row];
        [UIPasteboard generalPasteboard].string = message[@"content"] ?: @"";
    }
}

@end
