//
//  PaymentViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 17/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//
#import "AddPaymentViewController.h"
#import "MBProgressHUD.h"
#import "Mixpanel.h"
#import <Appsee/Appsee.h>
#import "Heap.h"

@interface AddPaymentViewController ()

- (void)hasError:(NSError *)error;
- (void)hasToken:(STPToken *)token;

@end

@implementation AddPaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup save button
    self.saveButton.enabled = NO;
    self.paymentLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"credit_card"];

    
    // Setup checkout
    self.checkoutView = [[STPView alloc] initWithFrame:CGRectMake(15,100,290,55) andKey:STRIPE_PUBLISHABLE_KEY];
    self.checkoutView.delegate = self;
    [self.view addSubview:self.checkoutView];
    

}
- (IBAction)cancel:(id)sender {
    //If it's coming from AddPayment then go to the ParkVC
    if ([self.presentingViewController isKindOfClass:[AddPhoneViewController class]]) {
        
        // Track event
        [Heap track:@"Cancel Card"];

        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate userLoggedIn];
    }
    //Else dismiss
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)stripeView:(STPView *)view withCard:(PKCard *)card isValid:(BOOL)valid
{
    // Enable save button if the Checkout is valid
    self.saveButton.enabled = YES;
}

- (IBAction)save:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.saveButton.enabled=NO;
    
    [self.checkoutView createToken:^(STPToken *token, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (error) {
            [self hasError:error];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Card error"];
        } else {
            [self hasToken:token];
        }
    }];
    
}

- (void)hasError:(NSError *)error
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:@"Your card is not valid. Call us if you need help"
                                                     delegate:self
                                            cancelButtonTitle:@"Retry"
                                            otherButtonTitles:@"Call support",nil];
    [message show];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSUserDefaults* userDefaults=[NSUserDefaults standardUserDefaults];
        NSString* supportNumber =[userDefaults objectForKey:@"support_number"];
        NSString *phoneNumber = [supportNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *phoneURL = [NSString stringWithFormat:@"tel:%@",phoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneURL]];
    }
}

- (void)hasToken:(STPToken *)token
{
    NSLog(@"Stripe card token %@", token.tokenId);
    NSLog(@"Card type %@", token.card.type);
    
    // Define variables
    NSString *cardNumber = [[NSString alloc] initWithFormat:@"•••%@",token.card.last4];
    NSString *cardType = token.card.type;

    // Store last4 digits and card type in phone
    [[NSUserDefaults standardUserDefaults] setObject:cardNumber forKey:@"cardNumber"];
    [[NSUserDefaults standardUserDefaults] setObject:cardType forKey:@"cardType"];

    // Set user properties
    User *theUser = [User theUser];
    theUser.cardNumber = cardNumber;
    theUser.cardType = cardType;

    // Send card token to back-end
    NSDictionary *cardParams = [NSDictionary dictionaryWithObjectsAndKeys:token.tokenId, @"card_token", [User theUser].token,@"auth_token", nil];
    
    NSString *baseURL = API_URL;
    NSString *path = [NSString stringWithFormat:@"/users/%@",[User theUser].id];
    NSString *url = [baseURL stringByAppendingString:path];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager PUT:url parameters:cardParams success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (!theUser.isCustomer) {
           
            // Track Mixpanel
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Save card"];
            [mixpanel.people set:@{@"Card saved": @"1"}];
            
            // Send to Appsee
            [Appsee addEvent:@"Card saved"];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            // The user is now a customer
            [userDefaults setObject:JSON[@"user"][@"is_customer"] forKey:@"isCustomer"];
            theUser.isCustomer = [JSON[@"user"][@"is_customer"] boolValue];
            
            // Update his credits
            [userDefaults setObject:JSON[@"user"][@"credits"] forKey:@"credits"];
            theUser.credits = JSON[@"user"][@"credits"];
            
            AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate userLoggedIn];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"NSError: %@",error.localizedDescription);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self hasError:error];
        
    }];
}

-(void) popVC
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
