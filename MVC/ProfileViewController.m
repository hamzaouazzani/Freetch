//
//  ProfileViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "ProfileViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "Mixpanel.h"

@interface ProfileViewController ()

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *sweetches;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (strong, nonatomic) IBOutlet FBLoginView *fbLoginView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation ProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.profilePicture.layer.cornerRadius=self.profilePicture.frame.size.width/2.0;
	// Do any additional setup after loading the view.
    
    //setup sidebarButton
    UIBarButtonItem *sidebarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:0 target:self.revealViewController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = sidebarButton;
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
   
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self populateUserDetails];
}

- (void)populateUserDetails
{
    User * user = [User theUser];
    self.userNameLabel.text = user.name;
    self.emailLabel.text= user.email;
    self.phoneLabel.text= user.phoneNumber;
    if ([user.count_sweetch integerValue]>1){
    self.sweetches.text= [NSString stringWithFormat: @"%@ sweetches",user.count_sweetch];
    }else{
        self.sweetches.text= [NSString stringWithFormat: @"%@ sweetch",user.count_sweetch];
    }
    self.profilePicture.profileID = user.facebook_id;
}

@end
