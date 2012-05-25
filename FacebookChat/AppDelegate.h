//
//  AppDelegate.h
//  FacebookChat
//
//  Created by Kanybek Momukeyev on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class XMPPStream;
@interface AppDelegate : UIResponder <UIApplicationDelegate,FBSessionDelegate> {
    Facebook *facebook;
    XMPPStream *xmppStream;
    
    BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
    
    UILabel *statusLabel;
}

@property (retain, nonatomic) UIWindow *window;

@property (readonly, retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, retain, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, retain, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)sendMessageToFacebook:(NSString*)textMessage withFriendFacebookID:(NSString*)friendID;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (retain, nonatomic) UINavigationController *navigationController;
@property (nonatomic, retain) Facebook *facebook;
@property (nonatomic,retain) UILabel *statusLabel;
@end
