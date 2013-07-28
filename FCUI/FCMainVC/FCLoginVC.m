//
//  FCLoginVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCLoginVC.h"
#import "FCAPIController.h"
#import "FCFacebookManager.h"
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
    [[FCAPIController sharedInstance] facebookManager].friendsResponseHandler = ^(NSArray *responseArray, NSError *error){
        if (!error) {
            [[[FCAPIController sharedInstance] chatDataStoreManager] differenceOfFriendsIdWithNewConversation:responseArray
                                                                                               withCompletion:^(NSNumber *sucess, NSError *eror){
               if (sucess) {
                   FCFriendsTVC *friendsTVC = [[FCFriendsTVC alloc] initWithNibName:@"FCFriendsTVC" bundle:nil];
                   [self_.navigationController pushViewController:friendsTVC animated:YES];
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
    [[[FCAPIController sharedInstance] facebookManager] authorize];
}

@end
