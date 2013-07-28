//
//  AppDelegate.m
//  FacebookChat
//
//  Created by Kanybek Momukeyev on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "XMPP.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "FCAPIController.h"
#import "FCChatDataStoreManager.h"
#import "FCLoginVC.h"
#import "FCAuthFacebookManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"MyDatabase.sqlite"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    FCLoginVC *loginVC = [[FCLoginVC alloc] initWithNibName:@"FCLoginVC" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[[FCAPIController sharedInstance] chatDataStoreManager] saveContext];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [[[FCAPIController sharedInstance] authFacebookManager] handleOpenURL:url];
}

@end
