//
//  FCMessageVC.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <UIKit/UIKit.h>
#import "JSMessagesViewController.h"
#import "Conversation.h"

@interface FCMessageVC : JSMessagesViewController <JSMessagesViewDelegate, JSMessagesViewDataSource>
@property (readwrite, nonatomic, strong) Conversation *conversation;
@end
