// Old
#import "ChatViewController.h"
#import "Message.h"
#import "Conversation.h"
#import "NSString+Additions.h"
#import "AppDelegate.h"
#import "XMPP.h"


#import "FCBaseChatRequestManager.h"
#import "FCAPIController.h"

// Exact same color as native iPhone Messages app.
// Achieved by taking a screen shot of the iPhone by pressing Home & Sleep buttons together.
// Then, emailed the image to myself and used Mac's native DigitalColor Meter app.
// Same => [UIColor colorWithRed:219.0/255.0 green:226.0/255.0 blue:237.0/255.0 alpha:1.0];
#define CHAT_BACKGROUND_COLOR [UIColor colorWithRed:0.859f green:0.886f blue:0.929f alpha:1.0f]

#define VIEW_WIDTH    self.view.frame.size.width
#define VIEW_HEIGHT    self.view.frame.size.height

#define RESET_CHAT_BAR_HEIGHT    SET_CHAT_BAR_HEIGHT(kChatBarHeight1)
#define EXPAND_CHAT_BAR_HEIGHT    SET_CHAT_BAR_HEIGHT(kChatBarHeight4)
#define    SET_CHAT_BAR_HEIGHT(HEIGHT)\
    CGRect chatContentFrame = _chatContent.frame;\
    chatContentFrame.size.height = VIEW_HEIGHT - HEIGHT;\
    [UIView beginAnimations:nil context:NULL];\
    [UIView setAnimationDuration:0.1f];\
    _chatContent.frame = chatContentFrame;\
    _chatBar.frame = CGRectMake(_chatBar.frame.origin.x, chatContentFrame.size.height,\
            VIEW_WIDTH, HEIGHT);\
    [UIView commitAnimations]

#define BAR_BUTTON(TITLE, SELECTOR) [[UIBarButtonItem alloc] initWithTitle:TITLE\
    style:UIBarButtonItemStylePlain target:self action:SELECTOR]

#define ClearConversationButtonIndex 0

// 15 mins between messages before we show the date
#define SECONDS_BETWEEN_MESSAGES        (60*15)

static CGFloat const kSentDateFontSize = 13.0f;
static CGFloat const kMessageFontSize   = 16.0f;   // 15.0f, 14.0f
static CGFloat const kMessageTextWidth  = 180.0f;
static CGFloat const kContentHeightMax  = 84.0f;  // 80.0f, 76.0f
static CGFloat const kChatBarHeight1    = 40.0f;
static CGFloat const kChatBarHeight4    = 94.0f;

@implementation ChatViewController

@synthesize receiveMessageSound = _receiveMessageSound;
@synthesize conversation = _conversation;
@synthesize chatContent = _chatContent;
@synthesize chatBar = _chatBar;
@synthesize chatInput = _chatInput;
@synthesize previousContentHeight = _previousContentHeight;
@synthesize sendButton = _sendButton;

@synthesize cellMap;


#pragma mark NSObject

- (void)dealloc {
    if (_receiveMessageSound) AudioServicesDisposeSystemSoundID(_receiveMessageSound);
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

#pragma mark UIViewController

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.chatContent = nil;
    self.chatBar = nil;
    self.chatInput = nil;
    self.sendButton = nil;
    self.cellMap = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    self.title = self.conversation.facebookName;
    // empty our badge number.
    _conversation.badgeNumber = [NSNumber numberWithInt:0];
    NSError *error;
    if (![_conversation.managedObjectContext save:&error]) { 
        NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
    }
    
    // Listen for keyboard.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:)
                                                 name:@"messageCome" object:nil];
    
    self.view.backgroundColor = CHAT_BACKGROUND_COLOR; // shown during rotation    
    
    // Create chatContent.
    _chatContent = [[UITableView alloc] initWithFrame:
                   CGRectMake(0.0f, 0.0f, self.view.frame.size.width,
                              self.view.frame.size.height-kChatBarHeight1)];
    _chatContent.clearsContextBeforeDrawing = NO;
    _chatContent.delegate = self;
    _chatContent.dataSource = self;
    _chatContent.contentInset = UIEdgeInsetsMake(7.0f, 0.0f, 0.0f, 0.0f);
    _chatContent.backgroundColor = CHAT_BACKGROUND_COLOR;
    _chatContent.separatorStyle = UITableViewCellSeparatorStyleNone;
    _chatContent.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_chatContent];
    
    // Create chatBar.
    _chatBar = [[UIImageView alloc] initWithFrame:
               CGRectMake(0.0f, self.view.frame.size.height-kChatBarHeight1,
                          self.view.frame.size.width, kChatBarHeight1)];
    _chatBar.clearsContextBeforeDrawing = NO;
    _chatBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleWidth;
    _chatBar.image = [[UIImage imageNamed:@"ChatBar.png"]
                     stretchableImageWithLeftCapWidth:18 topCapHeight:20];
    _chatBar.userInteractionEnabled = YES;
    
    // Create chatInput.
    _chatInput = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 9.0f, 234.0f, 22.0f)];
    _chatInput.contentSize = CGSizeMake(234.0f, 22.0f);
    _chatInput.delegate = self;
    _chatInput.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _chatInput.scrollEnabled = NO; // not initially
    _chatInput.scrollIndicatorInsets = UIEdgeInsetsMake(5.0f, 0.0f, 4.0f, -2.0f);
    _chatInput.clearsContextBeforeDrawing = NO;
    _chatInput.font = [UIFont systemFontOfSize:kMessageFontSize];
    _chatInput.dataDetectorTypes = UIDataDetectorTypeAll;
    _chatInput.backgroundColor = [UIColor clearColor];
    _previousContentHeight = _chatInput.contentSize.height;
    [_chatBar addSubview:_chatInput];
    
    // Create sendButton.
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.clearsContextBeforeDrawing = NO;
    _sendButton.frame = CGRectMake(_chatBar.frame.size.width - 70.0f, 8.0f, 64.0f, 26.0f);
    _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | // multi-line input
    UIViewAutoresizingFlexibleLeftMargin;                       // landscape
    UIImage *sendButtonBackground = [UIImage imageNamed:@"SendButton.png"];
    [_sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateNormal];
    [_sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateDisabled];
    _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    _sendButton.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
    [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
    UIColor *shadowColor = [[UIColor alloc] initWithRed:0.325f green:0.463f blue:0.675f alpha:1.0f];
    [_sendButton setTitleShadowColor:shadowColor forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendMessage)
         forControlEvents:UIControlEventTouchUpInside];
    
    [self resetSendButton]; // disable initially
    [_chatBar addSubview:_sendButton];
    
    [self.view addSubview:_chatBar];
    [self.view sendSubviewToBack:_chatBar];
        
    
    // Construct cellMap from fetchedObjects.
    NSInteger capacity = [[self.conversation.messages allObjects] count] * 2;

    cellMap = [[NSMutableArray alloc]
               initWithCapacity:capacity];
    
    //sort messages by date.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	NSMutableArray *sortedMessages = [[NSMutableArray alloc] initWithArray:[_conversation.messages allObjects]];
	[sortedMessages sortUsingDescriptors:sortDescriptors];
	    
	
    
    for (Message *message in sortedMessages) {
        [self addMessage:message];
    }
    
    // TODO: Implement check-box edit mode like iPhone Messages does. (Icebox)
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; // below: work around for [chatContent flashScrollIndicators]
    [_chatContent performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    [_chatInput resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {

    [super setEditing:(BOOL)editing animated:(BOOL)animated];
    [_chatContent setEditing:(BOOL)editing animated:(BOOL)animated]; // forward method call
//    chatContent.separatorStyle = editing ?
//            UITableViewCellSeparatorStyleSingleLine : UITableViewCellSeparatorStyleNone;
    
    if (editing) {
        UIBarButtonItem *clearAllButton = BAR_BUTTON(NSLocalizedString(@"Clear All", nil),
                                                     @selector(clearAll));
        self.navigationItem.leftBarButtonItem = clearAllButton;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
//    if ([chatInput isFirstResponder]) {
//        NSLog(@"resign first responder");
//        [chatInput resignFirstResponder];
//    }
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {

    CGFloat contentHeight = textView.contentSize.height - kMessageFontSize + 2.0f;
    NSString *rightTrimmedText = @"";
    
    // NSLog(@"contentOffset: (%f, %f)", textView.contentOffset.x, textView.contentOffset.y);
    // NSLog(@"contentInset: %f, %f, %f, %f", textView.contentInset.top, textView.contentInset.right,
    //          textView.contentInset.bottom, textView.contentInset.left);
    // NSLog(@"contentSize.height: %f", contentHeight);
    
    if ([textView hasText]) {
        rightTrimmedText = [textView.text
                            stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
        
        //        if (textView.text.length > 1024) { // truncate text to 1024 chars
        //            textView.text = [textView.text substringToIndex:1024];
        //        }
        
        // Resize textView to contentHeight
        if (contentHeight != _previousContentHeight) {
            if (contentHeight <= kContentHeightMax) { // limit chatInputHeight <= 4 lines
                CGFloat chatBarHeight = contentHeight + 18.0f;
                SET_CHAT_BAR_HEIGHT(chatBarHeight);
                if (_previousContentHeight > kContentHeightMax) {
                    textView.scrollEnabled = NO;
                }
                textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
                [self scrollToBottomAnimated:YES];
           } else if (_previousContentHeight <= kContentHeightMax) { // grow
                textView.scrollEnabled = YES;
                textView.contentOffset = CGPointMake(0.0f, contentHeight-68.0f); // shift to bottom
                if (_previousContentHeight < kContentHeightMax) {
                    EXPAND_CHAT_BAR_HEIGHT;
                    [self scrollToBottomAnimated:YES];
                }
            }
        }
    } else { // textView is empty
        if (_previousContentHeight > 22.0f) {
            RESET_CHAT_BAR_HEIGHT;
            if (_previousContentHeight > kContentHeightMax) {
                textView.scrollEnabled = NO;
            }
        }
        textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
    }

    // Enable sendButton if chatInput has non-blank text, disable otherwise.
    if (rightTrimmedText.length > 0) {
        [self enableSendButton];
    } else {
        [self disableSendButton];
    }
    _previousContentHeight = contentHeight;
}

// Fix a scrolling quirk.
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {

    textView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    return YES;
}

#pragma mark ChatViewController

- (void)enableSendButton {

    if (_sendButton.enabled == NO) {
        _sendButton.enabled = YES;
        _sendButton.titleLabel.alpha = 1.0f;
    }
}

- (void)disableSendButton {

    if (_sendButton.enabled == YES) {
        [self resetSendButton];
    }
}

- (void)resetSendButton {

    _sendButton.enabled = NO;
    _sendButton.titleLabel.alpha = 0.5f; // Sam S. says 0.4f
}


# pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    [self resizeViewWithOptions:[notification userInfo]];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self resizeViewWithOptions:[notification userInfo]];
}

- (void)resizeViewWithOptions:(NSDictionary *)options {  

    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    [[options objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[options objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[options objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    CGRect viewFrame = self.view.frame;
    NSLog(@"viewFrame y: %@", NSStringFromCGRect(viewFrame));

    //    // For testing.
    //    NSLog(@"keyboardEnd: %@", NSStringFromCGRect(keyboardEndFrame));
    //    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
    //                             initWithBarButtonSystemItem:UIBarButtonSystemItemDone
    //                             target:chatInput action:@selector(resignFirstResponder)];
    //    self.navigationItem.leftBarButtonItem = doneButton;
    //    [doneButton release];

    CGRect keyboardFrameEndRelative = [self.view convertRect:keyboardEndFrame fromView:nil];
    NSLog(@"self.view: %@", self.view);
    NSLog(@"keyboardFrameEndRelative: %@", NSStringFromCGRect(keyboardFrameEndRelative));

    viewFrame.size.height =  keyboardFrameEndRelative.origin.y;
    self.view.frame = viewFrame;
    [UIView commitAnimations];
    
    [self scrollToBottomAnimated:YES];
    
    _chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
    _chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
}

- (void)scrollToBottomAnimated:(BOOL)animated {

    NSInteger bottomRow = [cellMap count] - 1;
    if (bottomRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
        [_chatContent scrollToRowAtIndexPath:indexPath
                           atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark Message

- (void)messageReceived:(NSNotification*)textMessage {
    
    NSLog(@"message received!");
    XMPPMessage *message = textMessage.object;        
    
    NSString *adressString = [NSString stringWithFormat:@"%@",[message fromStr]];
    NSString *newStr = [adressString substringWithRange:NSMakeRange(1, [adressString length]-1)];
    NSString *facebookID = [NSString stringWithFormat:@"%@",[[newStr componentsSeparatedByString:@"@"] objectAtIndex:0]];
    
    // if message is not empty and sender is same with our _facebookID.
    if([message isChatMessageWithBody]&&([facebookID isEqualToString:_conversation.facebookId])) {
        
        Message *msg = (Message *)[NSEntityDescription
                                   insertNewObjectForEntityForName:@"Message"
                                   inManagedObjectContext:self.conversation.managedObjectContext];
        
        msg.text = [NSString stringWithFormat:@"%@",[[message elementForName:@"body"] stringValue]];
        NSDate *now = [[NSDate alloc] init]; 
        msg.sentDate = now;
        
        // message did come, this will be on left
        msg.messageStatus = @(TRUE);
        
        [_conversation addMessagesObject:msg];
        
        NSError *error;
        if (![self.conversation.managedObjectContext save:&error]) { 
            // TODO: Handle the error appropriately.
            NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
        }
        
        [self clearChatInput];
        
        // to calculate our height and insert new message.
        NSUInteger cellCount = [cellMap count];
        NSArray *indexPaths;
        NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:cellCount inSection:0];
        
        if ([self addMessage:msg] == 1) {
            // NSLog(@"insert 1 row at index: %d", cellCount);
            indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath, nil];
        } else { // 2
            // NSLog(@"insert 2 rows at index: %d", cellCount);
            indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath,
                          [NSIndexPath indexPathForRow:cellCount+1 inSection:0], nil];
        }
        
        [_chatContent insertRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
        
        // must come after RESET_CHAT_BAR_HEIGHT above.
        [self scrollToBottomAnimated:YES]; 
        
        // Play sound or buzz, depending on user settings.
        NSString *sendPath = [[NSBundle mainBundle] pathForResource:@"basicsound" ofType:@"wav"];
        CFURLRef baseURL = (__bridge CFURLRef)[NSURL fileURLWithPath:sendPath];
        AudioServicesCreateSystemSoundID(baseURL, &_receiveMessageSound);
        AudioServicesPlaySystemSound(_receiveMessageSound);
        AudioServicesPlayAlertSound(_receiveMessageSound);     // use for receiveMessage (sound & vibrate)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // explicit vibrate
        

        // empty our badge number.
        _conversation.badgeNumber = [NSNumber numberWithInt:0];
        NSError *errorSave;
        if (![_conversation.managedObjectContext save:&errorSave]) { 
            NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
        }
    }
}


- (void)sendMessage {
    // TODO: Show progress indicator like iPhone Message app does. (Icebox)
    // [activityIndicator startAnimating];
    
    NSString *rightTrimmedMessage =[_chatInput.text stringByTrimmingTrailingWhitespaceAndNewlineCharacters];
    
    // Don't send blank messages.
    if (rightTrimmedMessage.length == 0) {
        [self clearChatInput];
        return;
    }
    
    // Create new message and save to Core Data and display by core data delegate methods.
    Message *newMessage = (Message *)[NSEntityDescription
                                      insertNewObjectForEntityForName:@"Message"
                                      inManagedObjectContext:self.conversation.managedObjectContext];
    newMessage.text = rightTrimmedMessage;
    NSDate *now = [[NSDate alloc] init]; 
    newMessage.sentDate = now; 
    
    // message to sent, this will be on right
    newMessage.messageStatus = FALSE;

    [_conversation addMessagesObject:newMessage];
    
    NSError *error;
    if (![self.conversation.managedObjectContext save:&error]) {
        // TODO: Handle the error appropriately.
        NSLog(@"sendMessage error %@, %@", error, [error userInfo]);
    }
    

    
    // will send to facebook!    
    [[[FCAPIController sharedInstance] chatRequestManager] sendMessageToFacebook:rightTrimmedMessage
                                                            withFriendFacebookID:_conversation.facebookId];
    
    [self clearChatInput];

    // to calculate our height and insert new message.
    NSUInteger cellCount = [cellMap count];
    NSArray *indexPaths;
    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:cellCount inSection:0];
    
    if ([self addMessage:newMessage] == 1) {
        // NSLog(@"insert 1 row at index: %d", cellCount);
        indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath, nil];
    } else { // 2
        // NSLog(@"insert 2 rows at index: %d", cellCount);
        indexPaths = [[NSArray alloc] initWithObjects:firstIndexPath,
                      [NSIndexPath indexPathForRow:cellCount+1 inSection:0], nil];
    }
    
    [_chatContent insertRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];

    // must come after RESET_CHAT_BAR_HEIGHT above.
    [self scrollToBottomAnimated:YES]; 
    
    // Play sound or buzz, depending on user settings.
    NSString *sendPath = [[NSBundle mainBundle] pathForResource:@"basicsound" ofType:@"wav"];
    CFURLRef baseURL = (__bridge CFURLRef)[NSURL fileURLWithPath:sendPath];
    AudioServicesCreateSystemSoundID(baseURL, &_receiveMessageSound);
    AudioServicesPlaySystemSound(_receiveMessageSound);
    AudioServicesPlayAlertSound(_receiveMessageSound);     // use for receiveMessage (sound & vibrate)
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // explicit vibrate
}



- (void)clearChatInput {

    _chatInput.text = @"";
    if (_previousContentHeight > 22.0f) {
        RESET_CHAT_BAR_HEIGHT;
        _chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
        _chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
        [self scrollToBottomAnimated:YES];       
    }
}

// Returns number of objects added to cellMap (1 or 2).
- (NSUInteger)addMessage:(Message *)message 
{
    // Show sentDates at most every 15 minutes.
    NSDate *currentSentDate = message.sentDate;
    NSUInteger numberOfObjectsAdded = 1;
    NSUInteger prevIndex = [cellMap count] - 1;
    
    // Show sentDates at most every 15 minutes.

    if([cellMap count])
    {
        BOOL prevIsMessage = [[cellMap objectAtIndex:prevIndex] isKindOfClass:[Message class]];
        if(prevIsMessage)
        {
            Message * temp = [cellMap objectAtIndex:prevIndex];
            NSDate * previousSentDate = temp.sentDate;
            // if there has been more than a 15 min gap between this and the previous message!
            if([currentSentDate timeIntervalSinceDate:previousSentDate] > SECONDS_BETWEEN_MESSAGES) 
            { 
                [cellMap addObject:currentSentDate];
                numberOfObjectsAdded = 2;
            }
        }
    }
    else
    {
        // there are NO messages, definitely add a timestamp!
        [cellMap addObject:currentSentDate];
        numberOfObjectsAdded = 2;
    }
    
    [cellMap addObject:message];
    
    return numberOfObjectsAdded;

}

// Returns number of objects removed from cellMap (1 or 2).
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index {
    
    // Remove message from cellMap.
    [cellMap removeObjectAtIndex:index];
    NSUInteger numberOfObjectsRemoved = 1;
    NSUInteger prevIndex = index - 1;
    NSUInteger cellMapCount = [cellMap count];
    
    BOOL isLastObject = index == cellMapCount;
    BOOL prevIsDate = [[cellMap objectAtIndex:prevIndex] isKindOfClass:[NSDate class]];
      /*
       if (isLastObject && prevIsDate || prevIsDate && ([[cellMap objectAtIndex:index] isKindOfClass:[NSDate class]])) {
      */
    
    if ((isLastObject && prevIsDate) || (prevIsDate && ([[cellMap objectAtIndex:index] isKindOfClass:[NSDate class]]))) {
        [cellMap removeObjectAtIndex:prevIndex];
        numberOfObjectsRemoved = 2;
    }
    return numberOfObjectsRemoved;
}

- (void)clearAll {
    UIActionSheet *confirm = [[UIActionSheet alloc]
                              initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                              destructiveButtonTitle:NSLocalizedString(@"Clear Conversation", nil)
                              otherButtonTitles:nil];
	
	// use the same style as the nav bar
	confirm.actionSheetStyle = (UIActionSheetStyle)self.navigationController.navigationBar.barStyle;
    
    [confirm showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
//    [confirm showInView:self.view];
    
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex {

	switch (buttonIndex) {
		case ClearConversationButtonIndex: {
            NSError *error;

            for (Message *message in self.conversation.messages) {
                [self.conversation.managedObjectContext deleteObject:message];
            }
            if (![self.conversation.managedObjectContext save:&error]) {
                // TODO: Handle the error appropriately.
                NSLog(@"Delete message error %@, %@", error, [error userInfo]);
            }
            
            [cellMap removeAllObjects];
            [_chatContent reloadData];
            
            [self setEditing:NO animated:NO];
            break;
		}
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [cellMap count];
}

#define SENT_DATE_TAG 101
#define TEXT_TAG 102
#define BACKGROUND_TAG 103

static NSString *kMessageCell = @"MessageCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UILabel *msgSentDate;
    UIImageView *msgBackground;
    UILabel *msgText;
    
    NSObject *object = (NSObject*)[cellMap objectAtIndex:[indexPath row]];
    UITableViewCell *cell;
    
    // Handle sentDate (NSDate).
    if ([object isKindOfClass:[NSDate class]]) {
        static NSString *kSentDateCellId = @"SentDateCell";
        cell = [tableView dequeueReusableCellWithIdentifier:kSentDateCellId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:kSentDateCellId];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // Create message sentDate lable
            msgSentDate = [[UILabel alloc] initWithFrame:
                            CGRectMake(-2.0f, 0.0f,
                                       tableView.frame.size.width, kSentDateFontSize+5.0f)];
            msgSentDate.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            msgSentDate.clearsContextBeforeDrawing = NO;
            msgSentDate.tag = SENT_DATE_TAG;
            msgSentDate.font = [UIFont boldSystemFontOfSize:kSentDateFontSize];
            msgSentDate.lineBreakMode = UILineBreakModeTailTruncation;
            msgSentDate.textAlignment = UITextAlignmentCenter;
            msgSentDate.backgroundColor = CHAT_BACKGROUND_COLOR; // clearColor slows performance
            msgSentDate.textColor = [UIColor grayColor];
            [cell addSubview:msgSentDate];
//            // Uncomment for view layout debugging.
//            cell.contentView.backgroundColor = [UIColor orangeColor];
//            msgSentDate.backgroundColor = [UIColor orangeColor];
        } else {
            msgSentDate = (UILabel *)[cell viewWithTag:SENT_DATE_TAG];
        }
        
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle]; // Jan 1, 2010
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];  // 1:43 PM
            
            // TODO: Get locale from iPhone system prefs. Then, move this to viewDidAppear.
            NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            [dateFormatter setLocale:usLocale];
        }
        
        msgSentDate.text = [dateFormatter stringFromDate:(NSDate *)object];
        
        return cell;
    }
    
    // Handle Message object.
    cell = [tableView dequeueReusableCellWithIdentifier:kMessageCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:kMessageCell];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Create message background image view
        msgBackground = [[UIImageView alloc] init];
        msgBackground.clearsContextBeforeDrawing = NO;
        msgBackground.tag = BACKGROUND_TAG;
        msgBackground.backgroundColor = CHAT_BACKGROUND_COLOR; // clearColor slows performance
        [cell.contentView addSubview:msgBackground];
        
        // Create message text label
        msgText = [[UILabel alloc] init];
        msgText.clearsContextBeforeDrawing = NO;
        msgText.tag = TEXT_TAG;
        msgText.backgroundColor = [UIColor clearColor];
        msgText.numberOfLines = 0;
        msgText.lineBreakMode = UILineBreakModeWordWrap;
        msgText.font = [UIFont systemFontOfSize:kMessageFontSize];
        [cell.contentView addSubview:msgText];
    } else {
        msgBackground = (UIImageView *)[cell.contentView viewWithTag:BACKGROUND_TAG];
        msgText = (UILabel *)[cell.contentView viewWithTag:TEXT_TAG];
    }
    
    // Configure the cell to show the message in a bubble. Layout message cell & its subviews.
    CGSize size = [[(Message *)object text] sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    
    Message *message = (Message*)object;
    
    UIImage *bubbleImage;
    // right bubble
    if (message.messageStatus) { 
        CGFloat editWidth = tableView.editing ? 32.0f : 0.0f;
        msgBackground.frame = CGRectMake(tableView.frame.size.width-size.width-34.0f-editWidth,
                                         kMessageFontSize-13.0f, size.width+34.0f,
                                         size.height+12.0f);
        bubbleImage = [[UIImage imageNamed:@"ChatBubbleGreen.png"]
                       stretchableImageWithLeftCapWidth:15 topCapHeight:13];
        msgText.frame = CGRectMake(tableView.frame.size.width-size.width-22.0f-editWidth,
                                   kMessageFontSize-9.0f, size.width+5.0f, size.height);
        msgBackground.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        msgText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
//        // Uncomment for view layout debugging.
//        cell.contentView.backgroundColor = [UIColor blueColor];
    }
    // left bubble
    else 
    { 
        msgBackground.frame = CGRectMake(0.0f, kMessageFontSize-13.0f,
                                         size.width+34.0f, size.height+12.0f);
        bubbleImage = [[UIImage imageNamed:@"ChatBubbleGray.png"]
                       stretchableImageWithLeftCapWidth:23 topCapHeight:15];
        msgText.frame = CGRectMake(22.0f, kMessageFontSize-9.0f, size.width+5.0f, size.height);
        msgBackground.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        msgText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }
    
    
    msgBackground.image = bubbleImage;
    msgText.text = [(Message *)object text];
    
    // Mark message as read.
    // Let's instead do this (asynchronously) from loadView and iterate over all messages
    if (![(Message *)object read]) { // not read, so save as read
        [(Message *)object setRead:[NSNumber numberWithBool:YES]];
        NSError *error;
        if (![self.conversation.managedObjectContext save:&error]) {
            // TODO: Handle the error appropriately.
            NSLog(@"Save message as read error %@, %@", error, [error userInfo]);
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[cellMap objectAtIndex:[indexPath row]] isKindOfClass:[Message class]];
    // return [[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] == kMessageCell;
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSObject *object = [cellMap objectAtIndex:indexPath.row];
        if ([object isKindOfClass:[NSDate class]]) {
            return;
        }
        // Remove message from managed object context by index path.
        [self.conversation.managedObjectContext deleteObject:(Message *)object];
        NSError *error;
        if (![self.conversation.managedObjectContext save:&error]) {
            // TODO: Handle the error appropriately.
            NSLog(@"Delete message error %@, %@", error, [error userInfo]);
        }
        
        NSArray *indexPaths;    
        if ([self removeMessageAtIndex:indexPath.row] == 1) {
            // NSLog(@"delete 1 row");
            indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
        } else { 
            // 2
            // NSLog(@"delete 2 rows");
            indexPaths = [[NSArray alloc] initWithObjects:indexPath,
                          [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0], nil];
        }
        
        [_chatContent deleteRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"height for row: %d", [indexPath row]);
    
    NSObject *object = [cellMap objectAtIndex:[indexPath row]];
    
    // Set SentDateCell height.
    if ([object isKindOfClass:[NSDate class]]) {
        return kSentDateFontSize + 7.0f;
    }
    
    // Set MessageCell height.
    CGSize size = [[(Message *)object text] sizeWithFont:[UIFont systemFontOfSize:kMessageFontSize]
                                       constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                                           lineBreakMode:UILineBreakModeWordWrap];
    return size.height + 17.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) { // disable slide to delete
        return UITableViewCellEditingStyleDelete;
        // return 3; // used to work for check boxes
    }
    return UITableViewCellEditingStyleNone;
}

@end
