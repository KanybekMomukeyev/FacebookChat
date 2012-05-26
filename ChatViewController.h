// Old
#import <AudioToolbox/AudioToolbox.h>

@class Message;
@class Conversation;

@interface ChatViewController : UIViewController <
UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIActionSheetDelegate> {
    NSMutableArray *messages; 
}

@property (nonatomic, retain) NSString *facebookID;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, assign) SystemSoundID receiveMessageSound;

@property (nonatomic, retain) UITableView *chatContent;

@property (nonatomic, retain) UIImageView *chatBar;
@property (nonatomic, retain) UITextView *chatInput;
@property (nonatomic, assign) CGFloat previousContentHeight;
@property (nonatomic, retain) UIButton *sendButton;

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
