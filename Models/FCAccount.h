//
//  FCAccount.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 8/3/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FCAccount : NSManagedObject

@property (nonatomic, retain) NSString * facebookId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *conversation;
@end

@interface FCAccount (CoreDataGeneratedAccessors)

- (void)addConversationObject:(NSManagedObject *)value;
- (void)removeConversationObject:(NSManagedObject *)value;
- (void)addConversation:(NSSet *)values;
- (void)removeConversation:(NSSet *)values;

@end
