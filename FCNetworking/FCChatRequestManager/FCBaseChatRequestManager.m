//
//  FCBaseChatRequestManager.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCBaseChatRequestManager.h"
#import "FCAPIController.h"
#import "FCAuthFacebookManager.h"

@interface FCBaseChatRequestManager ()
@end

@implementation FCBaseChatRequestManager

- (id)init
{
    if (self = [super init]) {
        _xmppStream = [[XMPPStream alloc] initWithFacebookAppId:FACEBOOK_APP_ID];
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}


#pragma mark XMPPStream Delegate methods
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
    if (![self.xmppStream isSecure])
    {
        NSLog(@"XMPP STARTTLS...");
        NSError *error = nil;
        BOOL result = [self.xmppStream secureConnection:&error];
        
        if (result == NO)
        {
            DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
            NSLog(@"XMPP STARTTLS failed");
        }
    }
    else
    {
        NSLog(@"XMPP X-FACEBOOK-PLATFORM SASL...");
        NSError *error = nil;
        BOOL result = [self.xmppStream authenticateWithFacebookAccessToken:[[FCAPIController sharedInstance] authFacebookManager].facebook.accessToken
                                                                     error:&error];
        
        if (result == NO)
        {
            DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
            NSLog(@"XMPP authentication failed");
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (NO)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (NO)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		NSString *expectedCertName = [sender hostName];
		if (expectedCertName == nil)
		{
			expectedCertName = [[sender myJID] domain];
		}
        
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"XMPP STARTTLS...");
    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"XMPP authenticated");
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@ - error: %@", THIS_FILE, THIS_METHOD, error);
    NSLog(@"XMPP authentication failed");
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"XMPP disconnected");
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    // we recived message
    [[NSNotificationCenter defaultCenter] postNotificationName:kFCMessageDidComeNotification
                                                        object:message];
}

#pragma mark send message to Facebook.
- (void)sendMessageToFacebook:(NSString*)textMessage withFriendFacebookID:(NSString*)friendID
{    
    if([textMessage length] > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:textMessage];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"xmlns" stringValue:@"http://www.facebook.com/xmpp/messages"];
        [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"-%@@chat.facebook.com",friendID]];
        [message addChild:body];
        [self.xmppStream sendElement:message];
    }
}

@end
