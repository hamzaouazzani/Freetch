//
//  LeaveConfirmationViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 24/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "LeaveConfirmationViewController.h"
#import "Mixpanel.h"
#import "Heap.h"

@interface LeaveConfirmationViewController ()

@property (weak, nonatomic) IBOutlet FBProfilePictureView *parkerPicture;
@property (weak, nonatomic) IBOutlet UIButton *confirmationButton;
@property (weak, nonatomic) IBOutlet UILabel *leaveLabel;
@property (strong, nonatomic) HelpViewController *helpViewController;
@property (strong, nonatomic) NSString *sweetchFailedMessage;

@end

@implementation LeaveConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Title
    self.navigationItem.title = @"Sweetch";
    
    // Get wording to display
    NSUserDefaults *userDefaults= [NSUserDefaults standardUserDefaults];
    [self.confirmationButton setTitle:[userDefaults objectForKey:@"confirmation_button_leave"] forState:UIControlStateNormal];
    self.sweetchFailedMessage= [userDefaults objectForKey:@"sweetch_failed_leaver"];
    
    // Instructions to user
    NSString *instructionsPlain = [userDefaults objectForKey:@"leave_label_confirm"];
    NSString *instructionsWithName = [instructionsPlain stringByReplacingOccurrencesOfString:@"parker_name" withString:self.sweetch.parker.first_name];
    NSString *instructionsWithNameAndEta = [instructionsWithName stringByReplacingOccurrencesOfString:@"eta" withString:self.sweetch.eta];
    self.leaveLabel.text = instructionsWithNameAndEta;
    
	// Do any additional setup after loading the view.
    self.parkerPicture.layer.cornerRadius = self.parkerPicture.frame.size.width/2.0;
    self.parkerPicture.profileID = self.sweetch.parker.facebook_id;
    self.navigationItem.hidesBackButton = YES;
    self.confirmationButton.hidden = NO;
    
    // Help button
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(pushHelpViewController)];
    self.navigationItem.rightBarButtonItem = helpButton;
    
    // Allow driver to be called if he has phone number
    if (self.sweetch.parker.phone) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Call driver"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(callDriver)];
    }
    
    // Confirmation button
    self.confirmationButton.layer.cornerRadius = 3;
    self.confirmationButton.layer.borderWidth = 1;
    UIColor *sweetchColor = [UIColor colorWithRed:26 green:129 blue:160 alpha:1];
    self.confirmationButton.layer.borderColor = sweetchColor.CGColor;
    
    // Link to help page
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.helpViewController= [mainStoryBoard instantiateViewControllerWithIdentifier:@"help"];
}

- (void)callDriver
{
    NSString *phoneNumber = [NSString stringWithFormat:@"tel:%@",self.sweetch.parker.phone];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

-(void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sweetchFailed) name:@"Sweetch Failed" object:appDelegate];
}

-(void) viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pushHelpViewController
{
    self.helpViewController.sweetch = self.sweetch;
    
    // Custom help page for a Leaver
    self.helpViewController.calledFromPark = NO;
    self.helpViewController.calledFromParkConfirmation = NO;
    self.helpViewController.calledFromLeave = YES;
   
    [self.navigationController pushViewController:self.helpViewController animated:YES];
}

- (IBAction)confirmSweetch:(id)sender
{
    // Track event
    [Heap track:@"Confirm Sweetch"];

    // Validate sweetch and send to backend
    self.sweetch.state = @"validated";
    [self.sweetch updateInBackend];
    [self sendFinalView];
}

- (void)sendFinalView
{
    // Update count_sweetch and credits
    [[User theUser] getUserFromBackend];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.leaveLabel.text = [[NSString alloc] initWithFormat:@"%@ %@!\n%@", [userDefaults objectForKey:@"leave_label_thanks"],self.sweetch.parker.first_name, [userDefaults objectForKey:@"leave_label_receive"]];
    self.confirmationButton.hidden = YES;

    self.navigationItem.rightBarButtonItem=nil;
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(goToMap) userInfo:nil repeats:NO];
  
}

-(void)goToMap{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)sweetchFailed{
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle: @"Sorry" message: self.sweetchFailedMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: @"Retry",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    LeaveViewController *leaveVC = self.navigationController.viewControllers[[self.navigationController.viewControllers count]-2];
    if (buttonIndex == 1) {
        leaveVC.retry = YES;
    }
    
    leaveVC.carLocationGiven = YES;
    leaveVC.carLocation = self.carLocation;
    [self.navigationController popToViewController:leaveVC animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

@end
