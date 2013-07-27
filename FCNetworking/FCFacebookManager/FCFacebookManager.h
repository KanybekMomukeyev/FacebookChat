//
//  FCFacebookManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPP.h"
#import "FBConnect.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#define FACEBOOK_APP_ID @"124242144347927"

@interface FCFacebookManager : NSObject
@property (readonly, nonatomic, strong) Facebook *facebook;

- (BOOL)handleOpenURL:(NSURL *)url;
- (void)authorize;
@end
