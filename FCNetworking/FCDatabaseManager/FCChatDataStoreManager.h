//
//  FCChatDataStoreManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "FCBaseDataStoreManager.h"

@interface FCChatDataStoreManager : FCBaseDataStoreManager
- (void)differenceOfFriendsIdWithNewConversation:(NSArray *)friendsArray
                                  withCompletion:(CompletionBlock)completion;
@end
