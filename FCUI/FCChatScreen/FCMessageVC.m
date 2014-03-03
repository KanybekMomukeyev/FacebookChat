//
//  FCMessageVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCMessageVC.h"
#import "Message.h"
#import "FCChatDataStoreManager.h"
#import "FCBaseChatRequestManager.h"
#import "FCAPIController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "XMPP.h"
#import "SDWebImageDownloader.h"
#import "FCUser.h"
#import "Sequencer.h"

@interface FCMessageVC ()
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) UIImage *senderImage;
@property (nonatomic, strong) UIImage *reciverImage;
@end

@implementation FCMessageVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.conversation.facebookName;
    [self setUpSequencer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.conversation.badgeNumber = @(0);
    [[[FCAPIController sharedInstance] chatDataStoreManager] saveContext];
    
    /* */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageReceived:)
                                                 name:kFCMessageDidComeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)setUpSequencer
{
    __weak FCMessageVC *self_ = self;
    Sequencer *sequencer = [Sequencer new];
    [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
        NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",self_.conversation.facebookId];
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:url]
                                                              options:0
                                                             progress:nil
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished){
                                                                if (!error) {
                                                                    self_.senderImage = image;
                                                                }
                                                                completion(nil);
                                                            }];
    }];
    
    [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
        NSString *urlMine = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",[FCAPIController sharedInstance].currentUser.userId];
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:urlMine]
                                                              options:0
                                                             progress:nil
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished){
                                                                if (!error) {
                                                                    self_.reciverImage = image;
                                                                }
                                                                completion(nil);
                                                            }];
    }];
    
    [sequencer enqueueStep:^(id result, SequencerCompletion completion) {
        self_.messages = [NSMutableArray arrayWithArray:[[[FCAPIController sharedInstance] chatDataStoreManager] fetchAllMessagesInConversation:self_.conversation]];
        self_.delegate = self_;
        self_.dataSource = self_;
        [self_.tableView reloadData];
        completion(nil);
    }];
    
    [sequencer run];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}


#pragma mark Message Notification Recived
- (void)messageReceived:(NSNotification*)textMessage
{
    NSLog(@"message received!");
    XMPPMessage *message = textMessage.object;
    NSString *adressString = [NSString stringWithFormat:@"%@",[message fromStr]];
    NSString *newStr = [adressString substringWithRange:NSMakeRange(1, [adressString length]-1)];
    NSString *facebookID = [NSString stringWithFormat:@"%@",[[newStr componentsSeparatedByString:@"@"] objectAtIndex:0]];
    
    // if message is not empty and sender is same with our _facebookID.
    if([message isChatMessageWithBody] && ([facebookID isEqualToString:self.conversation.facebookId]))
    {
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        Message *msg = [Message MR_createInContext:localContext];
        msg.text = [NSString stringWithFormat:@"%@",[[message elementForName:@"body"] stringValue]];
        msg.sentDate = [NSDate date];
        
        // message did come, this will be on left
        msg.messageStatus = @(YES);
        [self.conversation addMessagesObject:msg];
        [self.messages addObject:msg];
        [localContext MR_saveToPersistentStoreAndWait];
        
        [self finishSend];
        [JSMessageSoundEffect playMessageReceivedSound];
    }
    else if([message isChatMessageWithBody] &&(![facebookID isEqualToString:self.conversation.facebookId]))
    {
        // here message come fome another friend
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"facebookId = %@", facebookID];
        Conversation *conversation = [Conversation MR_findFirstWithPredicate:predicate inContext:localContext];
        
        Message *msg = [Message MR_createInContext:localContext];
        msg.text = [NSString stringWithFormat:@"%@",[[message elementForName:@"body"] stringValue]];
        msg.sentDate = [NSDate date];
        
        // message did come, this will be on left
        msg.messageStatus = @(YES);
        
        // increase badge number.
        int badgeNumber = [conversation.badgeNumber intValue];
        badgeNumber ++;
        conversation.badgeNumber = [NSNumber numberWithInt:badgeNumber];
        [conversation addMessagesObject:msg];
        [localContext MR_saveToPersistentStoreAndWait];
        

    }
}


#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    Message *msg = [Message MR_createInContext:localContext];
    msg.text = text;
    msg.sentDate = [NSDate date];
    
    // message did not come, this will be on rigth
    msg.messageStatus = @(NO);
    [self.conversation addMessagesObject:msg];
    [self.messages addObject:msg];
    [localContext MR_saveToPersistentStoreAndWait];
    
    /* */
    [[[FCAPIController sharedInstance] chatRequestManager] sendMessageToFacebook:text
                                                            withFriendFacebookID:self.conversation.facebookId];
    [JSMessageSoundEffect playMessageSentSound];
    [self finishSend];
}


- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.messages objectAtIndex:indexPath.row];
    if ([message.messageStatus boolValue]) {
        return JSBubbleMessageTypeIncoming;
    }else {
        return JSBubbleMessageTypeOutgoing;
    }
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleSquare;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyEveryThree;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyBoth;
}

- (JSAvatarStyle)avatarStyle
{
    return JSAvatarStyleSquare;
}


#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.messages objectAtIndex:indexPath.row];
    return message.text;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [self.messages objectAtIndex:indexPath.row];
    return message.sentDate;
}

- (UIImage *)avatarImageForIncomingMessage
{
    return self.senderImage;
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return self.reciverImage;
}
@end
