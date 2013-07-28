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

#import "FCAuthFacebookManager.h"
#import "FCFacebookManager/FCRequestFacebookManager.h"

@interface FCAPIController()
@property (nonatomic, strong) FCChatDataStoreManager *chatDataStoreManager;
@property (nonatomic, strong) FCBaseChatRequestManager *chatRequestManager;
@property (nonatomic, strong) FCAuthFacebookManager *authFacebookManager;
@property (nonatomic, strong) FCRequestFacebookManager *requestFacebookManager;
@end


@implementation FCAPIController
SINGLETON_GCD(FCAPIController);

- (FCAuthFacebookManager *)authFacebookManager {
    if (!_authFacebookManager) {
        _authFacebookManager = [FCAuthFacebookManager new];
    }
    return _authFacebookManager;
}

- (FCRequestFacebookManager *)requestFacebookManager {
    if (!_requestFacebookManager) {
        _requestFacebookManager = [FCRequestFacebookManager new];
    }
    return _requestFacebookManager;
}

- (FCChatDataStoreManager *)chatDataStoreManager {
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

@end
