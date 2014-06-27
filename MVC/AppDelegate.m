//
//  AppDelegate.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 05/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//
#import "AppDelegate.h"
#import "Mixpanel.h"
#import <Taplytics/Taplytics.h>
#import <Appsee/Appsee.h>
#import "Heap.h"

@implementation AppDelegate

# pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Setup Taplytics
    [Taplytics startTaplyticsAPIKey:TAPLYTICS_KEY];
    
    // Setup Heap Analytics
    [Heap setAppId:HEAP_KEY];
    [Heap track:@"Open app"];
    
    // Setup Appsee
//    [Appsee start:APPSEE_KEY];
    
    // Set up Mixpanel instance
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    // You must call identify if you haven't already
    NSLog(@"%@",mixpanel.distinctId);
    [mixpanel identify:mixpanel.distinctId];
    [mixpanel track:@"Open App"];

    // Set dots for onboarding flow
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"API URL: %@", API_URL);
    
    // Get the wording from back-end
    [self getAppWording];
    
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *startVC = [mainStoryBoard instantiateViewControllerWithIdentifier:@"StartViewController"];
    [self.window setRootViewController:startVC];
    [self.window makeKeyAndVisible];
    
    // Load loginVC
    self.loginViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"login"];
    

    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        if ([FBSession.activeSession.permissions indexOfObject:@"email"] == NSNotFound) {
            [FBSession.activeSession closeAndClearTokenInformation];
            [self userLoggedOut];
        } else {
            NSLog(@"Using cached token to authenticate user");
            // Since we have a cached token, do not show the Facebook login UI to open session
            self.newSession = NO;
            [self openFbSession];
        }

    } else {
        // New session => Go to the loginVC
        NSLog(@"New Facebook session");
        self.newSession = YES;
        [self.window setRootViewController:self.loginViewController];
    }

    // Load here for use later in other controllers
    [FBLoginView class];
    [FBProfilePictureView class];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [Heap track:@"Quit app"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Handle the user leaving the app while the Facebook login dialog is being shown
    [FBAppCall handleDidBecomeActive];
    
    [FBSettings setDefaultAppID:@"278547838962660"];
    [FBAppEvents activateApp];
    
    [Heap track:@"Returned to App"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
    
    // Check for turned on notifications only if the user is logged in
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        if ((types & UIRemoteNotificationTypeAlert) && [User theUser].isLoggedIn && ![User theUser].registeredForNotifications) {
            [self registerForRemoteNotifications];
        }
    }
}

// Handling the response from the facebook app
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    // Handling app cold starts -- happens if app is shutdown by ios during app switching
    [FBSession.activeSession setStateChangeHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
    
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

// Compute device token and store it for later use
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [NSString stringWithFormat:@"%@", [deviceToken description]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:token forKey:@"device_token"];
    
    User *theUser = [User theUser];
    theUser.registeredForNotifications = YES;
    
    // Once we recover the device token, we send it to the backend
    NSDictionary *parameters = @{@"facebook_id":[User theUser].facebook_id,
                                 @"device_token":token};
    [[User theUser] patchUserWithParameter:parameters];
    
    // This sends the deviceToken to Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people addPushDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed: %@", error);
}

// Triggered when a new push notification is received
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Remote notification received: %@", userInfo);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:userInfo[@"title"] object:self userInfo:userInfo];
}

# pragma mark - Facebook SDK

- (void)openFbSession
{
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email"]
                                       allowLoginUI:self.newSession
                                  completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                      // Handler for session state changes
                                      [self sessionStateChanged:session state:state error:error];
                                  }
     ];

}


// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        // Shows the user the logged-in UI
        [self logsInUser];
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
        // Show the user the logged-out UI
        User *theUser = [User theUser];
        theUser = nil;
        [self userLoggedOut];
    }

    // Handle errors
    if (error){
        NSLog(@"Error login Facebook");
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Error logging in" properties:@{@"error":[error localizedDescription]}];
        NSLog(@"%@",error);
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            [self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                [self showMessage:alertText withTitle:alertTitle];
                
                // Here we will handle all other errors with a generic error message.
                // We recommend you check our Handling Errors guide for more information
                // https://developers.facebook.com/docs/ios/errors/
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                [self showMessage:alertText withTitle:alertTitle];
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        // Show the user the logged-out UI
        [self userLoggedOut];
    }
}

- (void)askForFacebookEmail
{
    // Request publish_actions
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"email"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            if (!error) {
                                                if ([FBSession.activeSession.permissions
                                                     indexOfObject:@"email"] == NSNotFound){
                                                    // Permission not granted, tell the user we will not log him in
                                                    [[[UIAlertView alloc] initWithTitle:@"Permission not granted"
                                                                                message:@"We can't log you in without an email"
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil, nil] show];
                                                } else {
                                                    // Permission granted, log him in
                                                    [self logsInUser];
                                                }
                                                
                                            } else {
                                                // There was an error, handle it
                                                // See https://developers.facebook.com/docs/ios/errors/
                                            }
                                        }];

}

- (void)logsInUser
{
    // Check that we have the email permission
    if ([FBSession.activeSession.permissions indexOfObject:@"email"] == NSNotFound) {
        NSString *alertTitle = @"Email not granted";
        NSString *alertText = @"We need your facebook email address to authenticate you. Please login again and grant Sweetch email access";
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertText
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil] show];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn) name:@"UserInstantiated" object:nil];
        if ([User theUser].ready) {
            [self userLoggedIn];
        }
    }
    

}

// When the user is looged in, go the Park Navigation Controller
- (void)userLoggedIn
{
    NSLog(@"User is logged in");
    // Ask for phone number or card depending on state of the user
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Show card registration screen when user has not given it yet
    User *theUser = [User theUser];
    
    if (!theUser.phoneNumber) {
        // Ask for his phone number if we don't have it
        AddPhoneViewController *addPhoneVC = [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddPhoneViewController"];
        self.window.rootViewController = addPhoneVC;
    } else {
        // Show him the map if he completed the activation steps
        [User theUser].isLoggedIn = YES;
        self.revealVC = [mainStoryBoard instantiateViewControllerWithIdentifier:@"reveal"];
        [self.window setRootViewController:self.revealVC];
        
        // Register for Notifications
        // Fires a pop-up confirmation the first time
        [self registerForRemoteNotifications];
    }
    
}

// When he is logged out, go to the login screen
- (void)userLoggedOut
{
    // If the login screen is not already displayed, display it
    if (![self.window.rootViewController isKindOfClass:[LoginViewController class]]) {
        [self.window setRootViewController:self.loginViewController];
    } else {
        NSLog(@"there was an error, login screen is already displayed");
    }
}

- (void)registerForRemoteNotifications
{
    // Register for remote notifications
    // Triggers the method in case of success didRegisterForRemoteNotificationsWithDeviceToken
    UIApplication *application = [UIApplication sharedApplication];
    [application registerForRemoteNotificationTypes:(
                                                     UIRemoteNotificationTypeAlert |
                                                     UIRemoteNotificationTypeBadge |
                                                     UIRemoteNotificationTypeSound
                                                     )];
}

- (void)getAppWording
{
    // Get wording from back-end and store in userDefaults
    NSString *baseURL = API_URL;
    NSString *url = [baseURL stringByAppendingString:@"/message_views"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        NSLog(@"Received wording from back-end.");

        // Synchronize count Sweetch
        [userDefaults setObject:JSON[@"price_parker"] forKey:@"price_parker"];
        [userDefaults setObject:JSON[@"price_leaver"] forKey:@"price_leaver"];
        [userDefaults setObject:JSON[@"contacting_drivers"] forKey:@"contacting_drivers"];
        [userDefaults setObject:JSON[@"contacting_parkers"] forKey:@"contacting_parkers"];
        [userDefaults setObject:JSON[@"sweetch_failed_leaver"] forKey:@"sweetch_failed_leaver"];
        [userDefaults setObject:JSON[@"sweetch_failed_parker"] forKey:@"sweetch_failed_parker"];
        [userDefaults setObject:JSON[@"no_spot"] forKey:@"no_spot"];
        [userDefaults setObject:JSON[@"no_driver"] forKey:@"no_driver"];
        [userDefaults setObject:JSON[@"leaver_label_male"] forKey:@"leaver_label_male"];
        [userDefaults setObject:JSON[@"leaver_label_female"] forKey:@"leaver_label_female"];
        [userDefaults setObject:JSON[@"parked_at"] forKey:@"parked_at"];
        [userDefaults setObject:JSON[@"confirmation_button_park"] forKey:@"confirmation_button_park"];
        [userDefaults setObject:JSON[@"confirmation_button_leave"] forKey:@"confirmation_button_leave"];
        [userDefaults setObject:JSON[@"leave_label_confirm_v2"] forKey:@"leave_label_confirm"];
        [userDefaults setObject:JSON[@"leave_label_receive"] forKey:@"leave_label_receive"];
        [userDefaults setObject:JSON[@"leave_label_thanks"] forKey:@"leave_label_thanks"];
        [userDefaults setObject:JSON[@"sweetch_back"] forKey:@"sweetch_back"];
        [userDefaults setObject:JSON[@"what_happened"] forKey:@"what_happened"];
        [userDefaults setObject:JSON[@"call_us"] forKey:@"call_us"];
        [userDefaults setObject:JSON[@"button_1_from_park"] forKey:@"button_1_from_park"];
        [userDefaults setObject:JSON[@"button_2_from_park"] forKey:@"button_2_from_park"];
        [userDefaults setObject:JSON[@"button_3_from_park"] forKey:@"button_3_from_park"];
        [userDefaults setObject:JSON[@"button_1_from_leave"] forKey:@"button_1_from_leave"];
        [userDefaults setObject:JSON[@"button_2_from_leave"] forKey:@"button_2_from_leave"];
        [userDefaults setObject:JSON[@"button_1_from_park_confirmation"] forKey:@"button_1_from_park_confirmation"];
        [userDefaults setObject:JSON[@"support_number"] forKey:@"support_number"];
        [userDefaults setObject:JSON[@"credit_card"] forKey:@"credit_card"];
        [userDefaults setObject:JSON[@"login"] forKey:@"login"];
        [userDefaults setObject:JSON[@"warning_message"] forKey:@"warning_message"];
        [userDefaults setObject:JSON[@"wrong_neighborhood"] forKey:@"wrong_neighborhood"];
        [userDefaults setObject:JSON[@"notifications_not_allowed"] forKey:@"notifications_not_allowed"];
        [userDefaults setObject:JSON[@"waiting_time"] forKey:@"waiting_time"];
        [userDefaults setObject:JSON[@"leave_instructions"] forKey:@"leave_instructions"];
        [userDefaults setObject:JSON[@"phone_message"] forKey:@"phone_message"];
        [userDefaults setObject:JSON[@"leave_instructions_after_park"] forKey:@"leave_instructions_after_park"];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"NSError: %@",error.localizedDescription);
        
        // Default wording if network error
        [userDefaults setObject:@"$5" forKey:@"price_parker"];
        [userDefaults setObject:@"$4" forKey:@"price_leaver"];
        [userDefaults setObject:@"Contacting drivers" forKey:@"contacting_drivers"];
        [userDefaults setObject:@"Give us 5 minutes to find a match." forKey:@"contacting_parkers"];
        [userDefaults setObject:@"Your Sweetch buddy can't make it anymore" forKey:@"sweetch_failed_leaver"];
        [userDefaults setObject:@"Your Sweetch buddy can't make it anymore" forKey:@"sweetch_failed_parker"];
        [userDefaults setObject:@"No spot available for the moment." forKey:@"no_spot"];
        [userDefaults setObject:@"No driver looking for parking at the moment." forKey:@"no_driver"];
        [userDefaults setObject:@"Drive to leaver_name, he's standing outside his car." forKey:@"leaver_label_male"];
        [userDefaults setObject:@"Drive to leaver_name, she's standing outside her car." forKey:@"leaver_label_female"];
        [userDefaults setObject:@"Parked at" forKey:@"parked_at"];
        [userDefaults setObject:@"Ok" forKey:@"confirmation_button_park"];
        [userDefaults setObject:@"Confirm Sweetch" forKey:@"confirmation_button_leave"];
        [userDefaults setObject:@"parker_name is coming in eta. Wait outside your car and then confirm." forKey:@"leave_label_confirm"];
        [userDefaults setObject:@"You received $4 as a reward." forKey:@"leave_label_receive"];
        [userDefaults setObject:@"Thank you for helping" forKey:@"leave_label_thanks"];
        [userDefaults setObject:@"Recover your money when you leave" forKey:@"sweetch_back"];
        [userDefaults setObject:@"Something went wrong? Please tell us what happened." forKey:@"what_happened"];
        [userDefaults setObject:@"Need help? Call us at" forKey:@"call_us"];
        [userDefaults setObject:@"I could not find the car" forKey:@"button_1_from_park"];
        [userDefaults setObject:@"I found another spot" forKey:@"button_2_from_park"];
        [userDefaults setObject:@"Someone else took the spot" forKey:@"button_3_from_park"];
        [userDefaults setObject:@"I had to leave" forKey:@"button_1_from_leave"];
        [userDefaults setObject:@"I did not find the driver" forKey:@"button_2_from_leave"];
        [userDefaults setObject:@"I did not take the spot" forKey:@"button_1_from_park_confirmation"];
        [userDefaults setObject:@"+14152163537" forKey:@"support_number"];
        [userDefaults setObject:@"You will never be charged unless you park successfully" forKey:@"credit_card"];
        [userDefaults setObject:@"We will never post to facebook without asking you" forKey:@"login"];
        [userDefaults setObject:@"Only in the Mission" forKey:@"warning_message"];
        [userDefaults setObject:@"Sweetch is available only in the Mission District and for Giants games." forKey:@"wrong_neighborhood"];
        [userDefaults setObject:@"You must turn on your notifications to use Sweetch" forKey:@"notifications_not_allowed"];
        [userDefaults setObject:@"5" forKey:@"waiting_time"];
        [userDefaults setObject:@"Pin your car" forKey:@"leave_instructions"];
        [userDefaults setObject:@"So that other drivers can contact you" forKey:@"phone_message"];
    }];
}

// We have to send the error message to the Backend
-(void)showMessage:(NSString *)alertText withTitle:(NSString *)alertTitle
{
    NSLog(@"alertText:%@ alertTitle:%@",alertText,alertTitle);
    [[[UIAlertView alloc] initWithTitle:alertTitle
                                message:alertText
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:@"Call Support", nil] show];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[alert title] isEqualToString:@"Email not granted"]) {
        [self askForFacebookEmail];
    }
    if (buttonIndex == 1) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *supportNumber = [userDefaults objectForKey:@"support_number"];
        NSString *phoneNumber = [supportNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *phoneURL = [NSString stringWithFormat:@"tel:%@",phoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneURL]];
    }
}

@end
