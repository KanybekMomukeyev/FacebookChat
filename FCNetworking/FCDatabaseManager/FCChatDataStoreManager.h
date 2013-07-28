//
//  FCChatDataStoreManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
@class Conversation;

@interface FCChatDataStoreManager : NSObject

- (void)differenceOfFriendsIdWithNewConversation:(NSArray *)friendsArray
                                  withCompletion:(CompletionBlock)completion;
- (void)saveContext;
- (NSMutableArray *)fetchAllMessagesInConversation:(Conversation *)conversation;

@end
