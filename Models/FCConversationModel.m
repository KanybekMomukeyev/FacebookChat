//
//  FCConversationModel.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCConversationModel.h"

@implementation FCConversationModel

- (id)initWithFacebookId:(NSString *)facebookId
        withFacebookName:(NSString *)facebookName
{
    if (self = [super init]) {
        _facebookId = facebookId;
        _facebookName = facebookName;
    }
    return self;
}

- (BOOL)isEqual:(FCConversationModel *)other {
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    return [self.facebookId isEqualToString:other.facebookId];
}

- (NSUInteger)hash {
    return [self.facebookId longLongValue];
}

@end
