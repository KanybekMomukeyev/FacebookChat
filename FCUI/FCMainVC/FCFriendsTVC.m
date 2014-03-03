//
//  FCFriendsTVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCFriendsTVC.h"
#import "Conversation.h"
#import "FCConversationModel.h"
#import "UIImageView+WebCache.h"
#import "TDBadgedCell.h"
#import "XMPP.h"
#import "Message.h"
#import "NSString+Additions.h"
#import "FCChatDataStoreManager.h"
#import "FCAPIController.h"
#import "FCMessageVC.h"
#import "FCUser.h"

@interface FCFriendsTVC ()
@property (nonatomic, strong) NSArray *conversations;
@end

@implementation FCFriendsTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.conversations = [Conversation MR_findAll];
    self.title = [NSString stringWithFormat:@"Friends of %@",[FCAPIController sharedInstance].currentUser.name];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageReceived:)
                                                 name:kFCMessageDidComeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Message Notification Recived
- (void)messageReceived:(NSNotification*)textMessage {
    
    XMPPMessage *message = textMessage.object;
    if([message isChatMessageWithBody]) {
        
        NSString *adressString = [NSString stringWithFormat:@"%@",[message fromStr]];
        NSString *newStr = [adressString substringWithRange:NSMakeRange(1, [adressString length]-1)];
        NSString *facebookID = [NSString stringWithFormat:@"%@",[[newStr componentsSeparatedByString:@"@"] objectAtIndex:0]];
        
        NSLog(@"FACEBOOK_ID:%@",facebookID);
        
        // Build the predicate to find the person sought
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"facebookId = %@", facebookID];
        Conversation *conversation = [Conversation MR_findFirstWithPredicate:predicate inContext:localContext];
        
        Message *msg = [Message MR_createInContext:localContext];
        msg.text = [NSString stringWithFormat:@"%@",[[message elementForName:@"body"] stringValue]];
        msg.sentDate = [NSDate date];
        
        // message did come, this will be on left
        msg.messageStatus = @(TRUE);
        
        // increase badge number.
        int badgeNumber = [conversation.badgeNumber intValue];
        badgeNumber++;
        conversation.badgeNumber = [NSNumber numberWithInt:badgeNumber];
        [conversation addMessagesObject:msg];
        [localContext MR_saveOnlySelfAndWait];
        
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TDBadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    Conversation *conversation = [self.conversations objectAtIndex:indexPath.row];
    if([conversation.badgeNumber intValue] != 0) {
        cell.badgeString = [NSString stringWithFormat:@"%@", conversation.badgeNumber];
        cell.badgeColor = [UIColor colorWithRed:0.197 green:0.592 blue:0.219 alpha:1.000];
        cell.badge.radius = 9;
    }else {
        cell.badgeString = @"";
        cell.badgeColor = [UIColor clearColor];
        cell.badge.radius = 0;
    }
    
    NSString *url = [[NSString alloc]
                     initWithFormat:@"https://graph.facebook.com/%@/picture",conversation.facebookId];
    [cell.imageView setImageWithURL:[NSURL URLWithString:url]
                   placeholderImage:nil
                          completed:^(UIImage *image, NSError *error, SDImageCacheType type){}];
    cell.textLabel.text = conversation.facebookName;
    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FCMessageVC *messageVC = [[FCMessageVC alloc] initWithNibName:@"FCMessageVC" bundle:nil];
    messageVC.conversation = [self.conversations objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:messageVC animated:YES];
}

@end
