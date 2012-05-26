@class Message;

@interface Conversation : NSManagedObject {

}

@property (nonatomic, retain) id lastMessage;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, retain) NSString *facebookName;
@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, retain) NSNumber *badgeNumber;

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;


@end
