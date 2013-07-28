//
//  FCChatDataStoreManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>

@interface FCChatDataStoreManager : NSObject
- (void)differenceOfFriendsIdWithNewConversation:(NSArray *)friendsArray
                                  withCompletion:(CompletionBlock)completion;
- (void)saveContext;
@end
