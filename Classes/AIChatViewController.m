//
//  AIChatViewController.m
//  Artificially Inteligent
//

#import "AIChatViewController.h"
#import "AIMessageCell.h"
#import "AIAPIManager.h"
#import "AIConversationStore.h"
#import "AISettingsManager.h"
#import "AICompat.h"

static NSString * const kLoadingCellIdentifier = @"AILoadingCell";

@interface AIChatViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIToolbar *inputBar;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, assign) CGFloat inputBarHeight;
@property (nonatomic, assign) BOOL isWaitingForReply;

@end

@implementation AIChatViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Artificially Inteligent";
        self.inputBarHeight = 44.0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = AIIsIOS7OrLater() ? [UIColor whiteColor] : [UIColor colorWithWhite:0.95 alpha:1.0];
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
    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(clearButtonTapped)];
    self.navigationItem.rightBarButtonItem = clearButton;
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

#pragma mark - Input bar

- (void)setupInputBar {
    CGFloat width = CGRectGetWidth(self.view.bounds);

    self.inputBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - self.inputBarHeight, width, self.inputBarHeight)];
    self.inputBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    if (AIIsIOS7OrLater()) {
        self.inputBar.barTintColor = [UIColor whiteColor];
    }

    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(8, 6, width - 80, 32)];
    self.inputField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputField.placeholder = @"Message";
    self.inputField.delegate = self;
    self.inputField.returnKeyType = UIReturnKeySend;
    self.inputField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.inputBar addSubview:self.inputField];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.frame = CGRectMake(width - 64, 6, 56, 32);
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.sendButton];

    [self.view addSubview:self.inputBar];

    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.inputBarHeight, 0);
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
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);

    [UIView animateWithDuration:duration animations:^{
        CGRect barFrame = self.inputBar.frame;
        barFrame.origin.y = viewHeight - keyboardHeight - self.inputBarHeight;
        self.inputBar.frame = barFrame;

        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight + self.inputBarHeight, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    } completion:^(BOOL finished) {
        [self scrollToBottomAnimated:YES];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);

    [UIView animateWithDuration:duration animations:^{
        CGRect barFrame = self.inputBar.frame;
        barFrame.origin.y = viewHeight - self.inputBarHeight;
        self.inputBar.frame = barFrame;

        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.inputBarHeight, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
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
    [self.tableView reloadData]; // shows the typing/loading row
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
        // Loading/typing indicator row
        UITableViewCell *loadingCell = [tableView dequeueReusableCellWithIdentifier:kLoadingCellIdentifier];
        if (!loadingCell) {
            loadingCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLoadingCellIdentifier];
            loadingCell.selectionStyle = UITableViewCellSelectionStyleNone;
            loadingCell.backgroundColor = [UIColor clearColor];
            UIActivityIndicatorViewStyle style = AIIsIOS7OrLater() ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleGray;
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
            spinner.tag = 999;
            spinner.frame = CGRectMake(16, 8, 20, 20);
            [loadingCell.contentView addSubview:spinner];
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
        return 36.0; // loading row
    }
    NSDictionary *message = messages[indexPath.row];
    return [AIMessageCell heightForContent:message[@"content"] tableWidth:CGRectGetWidth(tableView.bounds)];
}

// Long-press-to-copy support, standard pattern since UITableView gained
// native menu support (iOS 5+). On iOS 3-4 this silently has no effect,
// which is an acceptable degradation for a "copy message" convenience.
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
