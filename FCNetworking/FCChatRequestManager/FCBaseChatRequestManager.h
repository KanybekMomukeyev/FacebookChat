//
//  FCBaseChatRequestManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

@interface FCBaseChatRequestManager : NSObject
@property (readonly, nonatomic, strong) XMPPStream *xmppStream;

- (void)sendMessageToFacebook:(NSString*)textMessage
         withFriendFacebookID:(NSString*)friendID;
@end
