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

#define FACEBOOK_APP_ID @"124242144347927"
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation AppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize navigationController = _navigationController;
@synthesize facebook = _facebook;
@synthesize statusLabel;

- (void)dealloc
{
    [_window release];
    [__managedObjectContext release];
    [__managedObjectModel release];
    [__persistentStoreCoordinator release];
    [_navigationController release];
    [_facebook release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
        
    MasterViewController *masterViewController = [[[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil] autorelease];
    self.navigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
    masterViewController.managedObjectContext = self.managedObjectContext;
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    
    xmppStream = [[XMPPStream alloc] initWithFacebookAppId:FACEBOOK_APP_ID];
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;
	
	_facebook = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID andDelegate:self];
	
    self.statusLabel.text = @"Starting Facebook Authentication";
    
	// Note: Be sure to invoke this AFTER the [self.window makeKeyAndVisible] method call above,
	//       or nothing will happen.
    [_facebook authorize:[NSArray arrayWithObject:@"xmpp_login"]];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Facebook Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return [_facebook handleOpenURL:url]; 
}

- (void)fbDidLogin
{    
	DDLogVerbose(@"%@: %@\nFacebook login successful!", THIS_FILE, THIS_METHOD);
	DDLogVerbose(@"%@: facebook.accessToken: %@", THIS_FILE, _facebook.accessToken);
	DDLogVerbose(@"%@: facebook.expirationDate: %@", THIS_FILE, _facebook.expirationDate);
	
    self.statusLabel.text = @"XMPP connecting...";
    
	NSError *error = nil;
	if (![xmppStream connect:&error])
	{
		DDLogError(@"%@: Error in xmpp connection: %@", THIS_FILE, error);
        self.statusLabel.text = @"XMPP connect failed";
	}
    
    // update the friends in MasterViewController
    [[NSNotificationCenter defaultCenter] postNotificationName:@"facebookAuthorized" object:nil];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.statusLabel.text = @"Facebook login failed";
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)sendMessageToFacebook:(NSString*)textMessage withFriendFacebookID:(NSString*)friendID {

    if([textMessage length] > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:textMessage];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"xmlns" stringValue:@"http://www.facebook.com/xmpp/messages"];
        [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"-%@@chat.facebook.com",friendID]];
        [message addChild:body];
        [xmppStream sendElement:message];
    }
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
    if (![xmppStream isSecure])
    {
        self.statusLabel.text = @"XMPP STARTTLS...";
        NSError *error = nil;
        BOOL result = [xmppStream secureConnection:&error];
        
        if (result == NO)
        {
            DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
            self.statusLabel.text = @"XMPP STARTTLS failed";
            NSLog(@"XMPP STARTTLS failed");
        }
    } 
    else 
    {
        self.statusLabel.text = @"XMPP X-FACEBOOK-PLATFORM SASL...";
        NSError *error = nil;
        BOOL result = [xmppStream authenticateWithFacebookAccessToken:_facebook.accessToken error:&error];
        
        if (result == NO)
        {
            DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
            self.statusLabel.text = @"XMPP authentication failed";
            NSLog(@"XMPP authentication failed");
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
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
    self.statusLabel.text = @"XMPP STARTTLS...";
    NSLog(@"XMPP STARTTLS...");
    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.statusLabel.text = @"XMPP authenticated";
    NSLog(@"XMPP authenticated");
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@ - error: %@", THIS_FILE, THIS_METHOD, error);
    self.statusLabel.text = @"XMPP authentication failed";
    NSLog(@"XMPP authentication failed");
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.statusLabel.text = @"XMPP disconnected";
    NSLog(@"XMPP disconnected");
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message 
{
    NSString *body = [[message elementForName:@"body"] stringValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"messageCome" object:body];
}


#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AcaniChat" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FacebookChat.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
