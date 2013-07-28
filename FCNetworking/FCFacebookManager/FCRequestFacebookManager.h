//
//  FCRequestFacebookManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>

@interface FCRequestFacebookManager : NSObject
- (void)requestGraphMeWithCompletion:(CompletionBlock)completion;
- (void)requestGraphFriendsWithCompletion:(CompletionBlock)completion;
@end
