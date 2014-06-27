//
//  AddPhoneViewController.m
//  MVC
//
//  Created by Thomas on 28/05/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "AddPhoneViewController.h"
#import <Appsee/Appsee.h>

@implementation AddPhoneViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nextButton.enabled=YES;
    
    NSString *phoneMessage = [[NSUserDefaults standardUserDefaults] objectForKey:@"phone_message"];
    self.phoneLabel.text = phoneMessage;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.phoneTextField becomeFirstResponder];
}

#pragma mark - IBAction

- (IBAction)next:(id)sender {
    // Change the UI
    self.nextButton.enabled=NO;
    
    // Validate number
    RMPhoneFormat *fmt = [[RMPhoneFormat alloc] init];
    NSString *phoneNumber = self.phoneTextField.text;
    BOOL valid = [fmt isPhoneNumberValid:phoneNumber];
    if (valid) {
        // Save number in backend
        User *theUser = [User theUser];
        theUser.phoneNumber = phoneNumber;
        [theUser patchUserWithParameter:@{@"phone":phoneNumber}];
        
        // Send to Appsee
        [Appsee addEvent:@"Phone saved"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(phoneUpdatedInBackend) name:@"UserUpdatedInBackend" object:nil];
    } else {
        [self phoneNumberNotValid];
    }
}

- (void)phoneNumberNotValid
{
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Invalid Phone Number"
                                                    message:@"Your phone number is not valid. Call us if you need help"
                                                   delegate:self
                                          cancelButtonTitle:@"Retry"
                                          otherButtonTitles:@"Call support", nil];
    [error show];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Phone number error"];
    
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSUserDefaults* userDefaults=[NSUserDefaults standardUserDefaults];
        NSString* supportNumber =[userDefaults objectForKey:@"support_number"];
        NSString *phoneNumber = [supportNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *phoneURL = [NSString stringWithFormat:@"tel:%@",phoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneURL]];
    }
}

- (void)phoneUpdatedInBackend
{
    User *theUser = [User theUser];
    if (theUser.isCustomer) {
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate userLoggedIn];
    } else {
        [self performSegueWithIdentifier:@"ShowAddPayment" sender:nil];
    }
}

@end
