//
//  HelpViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 19/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "HelpViewController.h"
#import "UIButton+Feedback.h"
#import "Mixpanel.h"
#import "Heap.h"

@interface HelpViewController ()

@property (strong, nonatomic) IBOutlet UIButton *feedbackBtn1;
@property (strong, nonatomic) IBOutlet UIButton *feedbackBtn2;
@property (strong, nonatomic) IBOutlet UIButton *feedbackBtn3;
@property (strong, nonatomic) ParkViewController *parkVC;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet UILabel *whatHappened;
@property (weak, nonatomic) IBOutlet UILabel *callUs;
@property (weak, nonatomic) IBOutlet UIButton *supportNumber;
@property (strong, nonatomic) NSString *sweetchFailedMessage;



@end

@implementation HelpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Track event
    [Heap track:@"View help"];
    
    // Wording
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.whatHappened.text= [userDefaults objectForKey:@"what_happened"];
    self.callUs.text=[userDefaults objectForKey:@"call_us"];
    [self.supportNumber setTitle:[userDefaults objectForKey:@"support_number"] forState:UIControlStateNormal];
    
    
	// If the help View Controller is called from the park View
    self.alertLabel.hidden = YES;

    // Initiate parkVC
    self.parkVC = self.navigationController.viewControllers.firstObject;
    
    if(self.calledFromPark) {
        self.sweetchFailedMessage = [userDefaults objectForKey:@"sweetch_failed_parker"];
        self.feedbackBtn1.feedback_id = [[NSNumber alloc] initWithInt:1];
        [self.feedbackBtn1 setTitle:@"I could not find the car" forState:UIControlStateNormal];
        self.feedbackBtn2.feedback_id = [[NSNumber alloc] initWithInt:2];
        [self.feedbackBtn2 setTitle:@"I found another spot" forState:UIControlStateNormal];
        self.feedbackBtn3.feedback_id = [[NSNumber alloc] initWithInt:3];
        [self.feedbackBtn3 setTitle:@"Someone else took the spot" forState:UIControlStateNormal];
        self.parkVC.backFromHelp = YES;
    } else if (self.calledFromLeave) {
        self.sweetchFailedMessage = [userDefaults objectForKey:@"sweetch_failed_leaver"];
        //display the leave HelpView
        self.feedbackBtn1.feedback_id = [[NSNumber alloc] initWithInt:4];
        [self.feedbackBtn1 setTitle:@"I had to leave" forState:UIControlStateNormal];
        self.feedbackBtn2.feedback_id = [[NSNumber alloc] initWithInt:5];
        [self.feedbackBtn2 setTitle:@"I did not find the driver" forState:UIControlStateNormal];
        self.feedbackBtn3.hidden=YES;
    } else if (self.calledFromParkConfirmation) {
        // display the payment contest buttons
        self.feedbackBtn1.feedback_id = [[NSNumber alloc] initWithInt:6];
        [self.feedbackBtn1 setTitle:@"I did not take the spot" forState:UIControlStateNormal];
        self.feedbackBtn2.hidden = YES;
        self.feedbackBtn3.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sweetchFailed) name:@"Sweetch Failed" object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sweetchValidated) name:@"Sweetch Validated" object:appDelegate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sweetchFailed
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                    message:self.sweetchFailedMessage
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: @"Retry",nil];
    [alert show];
}

- (void)sweetchValidated
{
    [self.parkVC displayConfirmationView];
    // Setup backFromHelp in order to load parkVC initialView later
    self.parkVC.backFromHelp = NO;
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.alertLabel.hidden = YES;
    if (self.calledFromPark) {
        self.parkVC.backFromHelp = NO;
        self.parkVC.sweetchInProgress = NO;
        if (buttonIndex == 1) {
            self.parkVC.retry = YES;
        }
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.calledFromLeave) {
        LeaveViewController* leaveVC= self.navigationController.viewControllers[[self.navigationController.viewControllers count] -3];
        if (buttonIndex == 1) {
            leaveVC.retry=YES;
        }else{
            leaveVC.okTapped=YES;
        }
        [self.navigationController popToViewController: leaveVC animated:YES];
    }
}

// Called when user clicks on the support phone number
- (IBAction)call:(id)sender
{
    NSString *phoneNumber = [self.supportNumber.currentTitle stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *phoneURL = [NSString stringWithFormat:@"tel:%@",phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneURL]];
}

// User clicks on a feedback button, show an alert message and update in back-end
- (IBAction)feedbackSent:(UIButton *)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.alertLabel.hidden = NO;
    self.view.tintColor = [UIColor whiteColor];
    self.alertLabel.text = @"Thank you for your feedback";
    [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(backToVC) userInfo:nil repeats:NO];
    
    [self sendFeedback:sender];
}

- (void)sendFeedback:(UIButton *)sender
{
    // Contest sweetch and update in backend
    if (self.calledFromParkConfirmation) {
        // Track event
        [Heap track:@"Contest Sweetch"];
        self.sweetch.state = @"contested";
    } else {
        [Heap track:@"Fail Sweetch"];
        self.sweetch.state = @"failed";
        self.sweetch.feedback_id = sender.feedback_id;
    }
    
    // Track activity in Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Fail Sweetch" properties:@{@"Message":sender.titleLabel.text}];
    [mixpanel.people increment:@"Fail Sweetches" by:@1];

    [self.sweetch updateInBackend];
}

- (void)backToVC
{    
    self.alertLabel.hidden = YES;
    if (self.calledFromPark) {
        self.parkVC.backFromHelp = NO;
        self.parkVC.sweetchInProgress = NO;
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.calledFromLeave) {
        LeaveViewController* leaveVC= self.navigationController.viewControllers[[self.navigationController.viewControllers count] -3];
        leaveVC.carLocationGiven=NO;
        [self.navigationController popToViewController: leaveVC animated:YES];
    } else if (self.calledFromParkConfirmation) {
        [self.navigationController popToViewController:self.parkVC animated:YES];
    }

}

@end
