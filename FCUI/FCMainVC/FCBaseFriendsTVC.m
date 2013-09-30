//
//  FCBaseFriendsTVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 8/3/13.
//
//

#import "FCBaseFriendsTVC.h"
#import "FCAPIController.h"
#import "FCAuthFacebookManager.h"
#import "FCLoginVC.h"

@interface FCBaseFriendsTVC ()

@end

@implementation FCBaseFriendsTVC

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
    UIBarButtonItem *doneBarItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", @"")
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(logOut:)];
    self.navigationItem.rightBarButtonItem = doneBarItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                          withRowAnimation:UITableViewRowAnimationNone];
}


- (void)logOut:(id)sender
{
    [[[FCAPIController sharedInstance] authFacebookManager] logOut];
    FCLoginVC *loginVC = [[FCLoginVC alloc] initWithNibName:@"FCLoginVC" bundle:nil];
    [self.navigationController setViewControllers:@[loginVC] animated:YES];
}




#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
