#import "Message.h"

@implementation Message

@dynamic sentDate;
@dynamic read;
@dynamic text;

// We need to implement getter and setter if we want to work for IOS 4
// CoreData mecanism is diffrent from IOS 5
- (BOOL)messageStatus
{
    [self willAccessValueForKey:@"messageStatus"];
    BOOL b = messageStatus;
    [self didAccessValueForKey:@"messageStatus"];
    return b;
}

- (void)setMessageStatus:(BOOL)newMessageStatus
{
    [self willChangeValueForKey:@"messageStatus"];
    messageStatus = newMessageStatus;
    [self didChangeValueForKey:@"messageStatus"];
}

@end
