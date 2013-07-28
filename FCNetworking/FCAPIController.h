//
//  FCAPIController.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "FCUser.h"

#define kFCMessageDidComeNotification @"kFCMessageDidComeNotification"

@class FCChatDataStoreManager;
@class FCBaseChatRequestManager;
@class FCAuthFacebookManager;
@class FCRequestFacebookManager;

@interface FCAPIController : NSObject
+ (FCAPIController *)sharedInstance;

@property (nonatomic, strong) FCUser *currentUser;
@property (readonly , nonatomic, strong) FCChatDataStoreManager *chatDataStoreManager;
@property (readonly , nonatomic, strong) FCBaseChatRequestManager *chatRequestManager;
@property (readonly , nonatomic, strong) FCAuthFacebookManager *authFacebookManager;
@property (readonly , nonatomic, strong) FCRequestFacebookManager *requestFacebookManager;
@end
