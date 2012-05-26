@class Message;

@interface Conversation : NSManagedObject {

}

@property (nonatomic, retain) id lastMessage;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSString *facebookId;


- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;


@end
