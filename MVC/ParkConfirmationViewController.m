//
//  ConfirmationViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 19/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "ParkConfirmationViewController.h"
#import "Heap.h"

@interface ParkConfirmationViewController ()

@property (weak, nonatomic) IBOutlet FBProfilePictureView *leaverPicture;
@property (weak, nonatomic) IBOutlet UILabel *paymentLabel;
@property (weak, nonatomic) IBOutlet UILabel *sweetchBack;
@property (strong, nonatomic) IBOutlet UIButton *confirmationButton;



@end

@implementation ParkConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title= @"Sweetch";
    
    // Wording to display
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    self.paymentLabel.text = [NSString stringWithFormat:@"You paid %@ to %@", [userDefaults objectForKey:@"price_parker"], self.sweetch.leaver.first_name];
    self.sweetchBack.text = [userDefaults objectForKey:@"sweetch_back"];
    [self.confirmationButton setTitle:[userDefaults objectForKey:@"confirmation_button_park"] forState: UIControlStateNormal] ;

	// Do any additional setup after loading the view.
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(pushHelpViewController)];
    self.navigationItem.rightBarButtonItem = helpButton;
    self.leaverPicture.layer.cornerRadius = self.leaverPicture.frame.size.width/2.0;
    self.leaverPicture.profileID = self.sweetch.leaver.facebook_id;

    self.confirmationButton.layer.cornerRadius = 3;
    self.confirmationButton.layer.borderWidth = 1;
    UIColor *sweetchColor = [UIColor colorWithRed:26 green:129 blue:160 alpha:1];
    self.confirmationButton.layer.borderColor = sweetchColor.CGColor;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)paymentConfirmed:(id)sender {
    // Track event
    [Heap track:@"Ok parked"];
    
    //Update count_sweetch and credits
    [[User theUser] getUserFromBackend];
    CLLocationCoordinate2D carLocation = CLLocationCoordinate2DMake([self.sweetch.lat doubleValue], [self.sweetch.lng doubleValue]);
    
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LeaveViewController* leaveVC= [mainStoryBoard instantiateViewControllerWithIdentifier:@"leave"];
    leaveVC.carLocation = carLocation;
    leaveVC.carLocationGiven = YES;
    [self.navigationController pushViewController:leaveVC animated:YES];
    
}
- (void)pushHelpViewController
{
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HelpViewController * helpViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"help"];
    helpViewController.sweetch = self.sweetch;
    helpViewController.calledFromParkConfirmation = YES;
    [self.navigationController pushViewController:helpViewController animated:YES];
}
@end
