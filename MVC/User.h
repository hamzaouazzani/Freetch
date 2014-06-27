//
//  User.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "AFHTTPRequestOperationManager.h"

@interface User : NSObject

@property (strong, nonatomic) NSString *first_name;
@property (strong, nonatomic) NSString *last_name;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *count_sweetch;
@property (strong, nonatomic) NSString *facebook_id;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *customerToken;
@property (strong, nonatomic) NSString *cardNumber;
@property (strong, nonatomic) NSString *cardType;
@property (strong, nonatomic) NSString *gender;
@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSString *credits;
@property (strong, nonatomic) NSString *zipcode;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) CLLocation *location;

@property BOOL isCustomer;
@property BOOL finishedLoading;
@property BOOL coveredArea;
@property BOOL ready;
@property BOOL isLoggedIn;
@property BOOL registeredForNotifications;

+ (void)fillUserDefaultfromFacebook;
- (void)sendUserInformationsWithParameter:(NSDictionary *)parameter;
+ (User *) theUser;

- (void)patchUserWithParameter:(NSDictionary *)parameter;
- (void)getUserFromBackend;
- (void)saveLocation;
@end
