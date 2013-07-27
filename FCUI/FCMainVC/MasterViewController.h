//
//  MasterViewController.h
//  FacebookChat
//
//  Created by Kanybek Momukeyev on 1/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import <CoreData/CoreData.h>

@class DetailViewController;
@class Conversation;

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, FBRequestDelegate,
 FBDialogDelegate>{}

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (Conversation*)findConversationWithId:(NSString*)facebookId;
@end
