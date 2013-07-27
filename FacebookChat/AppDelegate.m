//
//  AppDelegate.m
//  FacebookChat
//
//  Created by Kanybek Momukeyev on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "XMPP.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "FCAPIController.h"
#import "FCChatDataStoreManager.h"
#import "FCFacebookManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
    masterViewController.managedObjectContext = [[FCAPIController sharedInstance] chatDataStoreManager].managedObjectContext;
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    
    [[[FCAPIController sharedInstance] facebookManager] authorize];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[[FCAPIController sharedInstance] chatDataStoreManager] saveContext];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [[[FCAPIController sharedInstance] facebookManager] handleOpenURL:url];
}

@end
