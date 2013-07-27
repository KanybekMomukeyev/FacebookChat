//
//  FCAPIController.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
@class FCChatDataStoreManager;
@class FCBaseChatRequestManager;
@class FCFacebookManager;

@interface FCAPIController : NSObject
+ (FCAPIController *)sharedInstance;
@property (readonly , nonatomic, strong) FCChatDataStoreManager *chatDataStoreManager;
@property (readonly , nonatomic, strong) FCBaseChatRequestManager *chatRequestManager;
@property (readonly , nonatomic, strong) FCFacebookManager *facebookManager;
@end
