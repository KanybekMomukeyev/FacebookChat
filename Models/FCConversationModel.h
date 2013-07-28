//
//  FCConversationModel.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>

@interface FCConversationModel : NSObject

@property (readonly, nonatomic, strong) NSString *facebookName;
@property (readonly, nonatomic, strong) NSString *facebookId;
- (id)initWithFacebookId:(NSString * )facebookId withFacebookName:(NSString *)facebookName;
@end
