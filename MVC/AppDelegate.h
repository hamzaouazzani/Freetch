//
//  AppDelegate.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 05/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "LoginViewController.h"
#import "AddPhoneViewController.h"
#import "AddPaymentViewController.h"
#import "User.h"
#import "SWRevealViewController.h"
#import "StartViewController.h"



@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController* navController;
@property (strong, nonatomic) SWRevealViewController* revealVC;
@property (strong, nonatomic) LoginViewController *loginViewController;
@property (strong, nonatomic) NSDictionary *userParameters;
@property (strong, nonatomic) NSString *deviceToken;
@property (strong, nonatomic) User *user;
@property BOOL newSession;
@property BOOL readyToUpdate;

- (void)openFbSession;
- (void)userLoggedIn;
@end
