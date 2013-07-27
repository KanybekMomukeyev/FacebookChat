//
//  FCAPIController.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCAPIController.h"
#import "Singleton.h"
#import "FCChatDataStoreManager.h"
#import "FCBaseChatRequestManager.h"
#import "FCFacebookManager.h"
@interface FCAPIController()
@property (nonatomic, strong) FCChatDataStoreManager *chatDataStoreManager;
@property (nonatomic, strong) FCBaseChatRequestManager *chatRequestManager;
@property (nonatomic, strong) FCFacebookManager *facebookManager;
@end


@implementation FCAPIController
SINGLETON_GCD(FCAPIController);


- (FCBaseDataStoreManager *)chatDataStoreManager {
    if (!_chatDataStoreManager) {
        _chatDataStoreManager = [FCChatDataStoreManager new];
    }
    return _chatDataStoreManager;
}


- (FCBaseChatRequestManager *)chatRequestManager {
    if (!_chatRequestManager) {
        _chatRequestManager = [FCBaseChatRequestManager new];
    }
    return _chatRequestManager;
}

- (FCFacebookManager *)facebookManager {
    if (!_facebookManager) {
        _facebookManager = [FCFacebookManager new];
    }
    return _facebookManager;
}

@end
