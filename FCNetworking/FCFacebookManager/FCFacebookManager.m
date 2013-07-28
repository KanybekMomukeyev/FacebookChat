//
//  FCFacebookManager.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCFacebookManager.h"
#import "FCAPIController.h"
#import "FCBaseChatRequestManager.h"

@interface FCFacebookManager() <FBSessionDelegate, FBRequestDelegate, FBDialogDelegate>
@end


@implementation FCFacebookManager

- (id)init {
    if (self = [super init]) {
        _facebook = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID andDelegate:self];
    }
    return self;
}

- (void)authorize {
    NSLog(@"Starting Facebook Authentication");
    [self.facebook authorize:[NSArray arrayWithObject:@"xmpp_login"]];
}

- (BOOL)handleOpenURL:(NSURL *)url {
   return [self.facebook handleOpenURL:url];
}


#pragma mark FBSessionDelegate Delegate methods
- (void)fbDidLogin
{
	DDLogVerbose(@"%@: %@\nFacebook login successful!", THIS_FILE, THIS_METHOD);
	DDLogVerbose(@"%@: facebook.accessToken: %@", THIS_FILE, self.facebook.accessToken);
	DDLogVerbose(@"%@: facebook.expirationDate: %@", THIS_FILE, self.facebook.expirationDate);
	
    NSLog(@"XMPP connecting...");
	NSError *error = nil;
	if (![[[FCAPIController sharedInstance] chatRequestManager].xmppStream connect:&error])
	{
		DDLogError(@"%@: Error in xmpp connection: %@", THIS_FILE, error);
        NSLog(@"XMPP connect failed");
        return;
	}
    
    [self.facebook requestWithGraphPath:@"me/friends" andDelegate:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"Facebook login failed");
}

- (void)fbDidLogout {
}

- (void)fbSessionInvalidated {
}


#pragma mark - FBRequestDelegate Methods
- (void)request:(FBRequest *)request didLoad:(id)result
{
    if ([result isKindOfClass:[NSArray class]] && ([result count] > 0)) {
        result = [result objectAtIndex:0];
    }
    
    NSArray *resultData = [result objectForKey:@"data"];
    NSLog(@"%@", resultData);
    
    if (self.friendsResponseHandler) {
        self.friendsResponseHandler(resultData, nil);
    }
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    if (self.friendsResponseHandler) {
        self.friendsResponseHandler(nil, error);
    }
}



@end
