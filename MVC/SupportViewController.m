//
//  SupportViewController.m
//  MVC
//
//  Created by Thomas on 24/05/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "SupportViewController.h"

@implementation SupportViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup the sidebar button
    UIBarButtonItem *sidebarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:0 target:self.revealViewController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = sidebarButton;
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (IBAction)callSupport:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *phoneNumber = [[userDefaults objectForKey:@"support_number"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *phoneURL = [NSString stringWithFormat:@"tel:%@",phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneURL]];
}




@end
