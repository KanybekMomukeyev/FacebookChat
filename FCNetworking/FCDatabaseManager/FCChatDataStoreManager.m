//
//  FCChatDataStoreManager.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCChatDataStoreManager.h"
#import "Conversation.h"
#import "FCConversationModel.h"

@implementation FCChatDataStoreManager

- (void)differenceOfFriendsIdWithNewConversation:(NSArray *)friendsArray
                                  withCompletion:(CompletionBlock)completion
{
    NSArray *cachedFriends = [Conversation MR_findAll];
    NSMutableArray *cachedConversations = [NSMutableArray new];
    [cachedFriends enumerateObjectsUsingBlock:^(Conversation *conversation, NSUInteger idx, BOOL *stop){
        FCConversationModel *model = [[FCConversationModel alloc] initWithFacebookId:conversation.facebookId
                                                                    withFacebookName:conversation.facebookName];
        [cachedConversations addObject:model];
    }];
    
    NSMutableArray *newConversations = [NSMutableArray new];
    [friendsArray enumerateObjectsUsingBlock:^(NSDictionary *frinedDict, NSUInteger idx, BOOL *stop){
        
        NSString *name    = [NSString stringWithFormat:@"%@",[frinedDict objectForKey:@"name"]];
        NSString *frienId = [NSString stringWithFormat:@"%@",[frinedDict objectForKey:@"id"]];        
        FCConversationModel *model = [[FCConversationModel alloc] initWithFacebookId:frienId
                                                                    withFacebookName:name];
        [newConversations addObject:model];
    }];
    
  
    NSSet *firstSet = [NSSet setWithArray:cachedConversations];
    NSMutableSet *secondSet = [NSMutableSet setWithArray:newConversations];

    
    NSLog(@"newConversations.count = %d", secondSet.count);
    [secondSet minusSet:firstSet];
    NSLog(@"AFTER MINUS newConversations.count = %d", secondSet.count);

    
    NSArray *afterMinusArray = [secondSet allObjects];
    if (afterMinusArray.count == 0) {
        if (completion)
            completion(@(YES), nil);
    }
    
    // Get the local context
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_contextForCurrentThread];
    [afterMinusArray enumerateObjectsUsingBlock:^(FCConversationModel *model, NSUInteger idx, BOOL *stop){
        Conversation *conversation = [Conversation MR_createInContext:localContext];
        conversation.facebookId = model.facebookId;
        conversation.facebookName = model.facebookName;
        conversation.badgeNumber = [NSNumber numberWithInt:0];
    }];
    
    // Save the modification in the local context
    // With MagicalRecords 2.0.8 or newer you should use the MR_saveNestedContexts
    [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL sucess, NSError *error){
        if (sucess) {
            NSLog(@"GOOD");
            if (completion)
                completion(@(sucess), nil);
        }else {
            if (completion)
                completion(nil, error);
        }
    }];
}

- (void)saveContext
{
    NSManagedObjectContext *localContext    = [NSManagedObjectContext MR_contextForCurrentThread];
    [localContext MR_saveToPersistentStoreWithCompletion:^(BOOL sucess, NSError *error){
        if (sucess) {
            NSLog(@"GOOD");
        }else {
            NSLog(@"ERROR");
        }
    }];
}


- (NSMutableArray *)fetchAllMessagesInConversation:(Conversation *)conversation
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sentDate" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	NSMutableArray *sortedMessages = [[NSMutableArray alloc] initWithArray:[conversation.messages allObjects]];
	[sortedMessages sortUsingDescriptors:sortDescriptors];
    return [NSMutableArray arrayWithArray:sortedMessages];
}

@end
