//
//  PaymentViewController.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 17/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPView.h"
#import "SWRevealViewController.h"
#import "PaymentViewController.h"
#import "User.h"
#import "AppDelegate.h"

@interface AddPaymentViewController : UIViewController <STPViewDelegate>

@property STPView* checkoutView;

@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UILabel *paymentLabel;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property BOOL changeCard;

- (IBAction)save:(id)sender;

@end