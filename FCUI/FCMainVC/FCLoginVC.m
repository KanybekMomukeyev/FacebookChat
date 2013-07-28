//
//  FCLoginVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCLoginVC.h"
#import "FCAPIController.h"
#import "FCAuthFacebookManager.h"
#import "FCRequestFacebookManager.h"
#import "FCUser.h"
#import "FCFriendsTVC.h"
#import "FCChatDataStoreManager.h"
@interface FCLoginVC ()

@end

@implementation FCLoginVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    __weak FCLoginVC *self_ = self;
    [[FCAPIController sharedInstance] authFacebookManager].facebookAuthHandler = ^(NSNumber *sucess, NSError *error){
        if (!error) {
            
            [[[FCAPIController sharedInstance] requestFacebookManager] requestGraphMeWithCompletion:^(NSDictionary *response, NSError *error){
                if (!error) {
                    FCUser *currentUser = [[FCUser alloc] initWithDict:response];
                    [[FCAPIController sharedInstance] setCurrentUser:currentUser];
                    [self_ getFriends];
                }
            }];
        }
    };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)loginButtonDidPressed:(id)sender {
    [[[FCAPIController sharedInstance] authFacebookManager] authorize];
}

- (void)getFriends
{
    __weak FCLoginVC *self_ = self;
    [[[FCAPIController sharedInstance] requestFacebookManager] requestGraphFriendsWithCompletion:^(NSArray *responseArray, NSError *error) {
        if (!error) {
            [[[FCAPIController sharedInstance] chatDataStoreManager] differenceOfFriendsIdWithNewConversation:responseArray
                                                                                               withCompletion:^(NSNumber *sucess, NSError *eror){
                                                                                                   if (sucess) {
                                                                                                       FCFriendsTVC *friendsTVC = [[FCFriendsTVC alloc] initWithNibName:@"FCFriendsTVC" bundle:nil];
                                                                                                       [self_.navigationController pushViewController:friendsTVC
                                                                                                                                             animated:YES];
                                                                                                   }
                                                                                               }];
        }
    }];
}

@end
