
#import <AudioToolbox/AudioToolbox.h>

@class Message;
@class Conversation;

@interface ChatViewController : UIViewController <
UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIActionSheetDelegate> {
    NSMutableArray *messages; 
}

@property (nonatomic, strong) Conversation *conversation;
@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, strong) UITableView *chatContent;

@property (nonatomic, strong) UIImageView *chatBar;
@property (nonatomic, strong) UITextView *chatInput;
@property (nonatomic, assign) CGFloat previousContentHeight;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, copy) NSMutableArray *cellMap;


- (void)enableSendButton;
- (void)disableSendButton;
- (void)resetSendButton;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)resizeViewWithOptions:(NSDictionary *)options;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (void)sendMessage;
- (void)clearChatInput;
- (NSUInteger)addMessage:(Message *)message;
- (NSUInteger)removeMessageAtIndex:(NSUInteger)index;
- (void)clearAll;

@end
