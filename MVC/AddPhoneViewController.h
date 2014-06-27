//
//  AddPhoneViewController.h
//  MVC
//
//  Created by Thomas on 28/05/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMPhoneFormat.h"
#import "AppDelegate.h"
#import "User.h"
#import "Mixpanel.h"

@interface AddPhoneViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *phoneTextField;
@property (strong, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end
