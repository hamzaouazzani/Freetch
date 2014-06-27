//
//  User.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "User.h"
#import "Mixpanel.h"
#import <Appsee/Appsee.h>
#import "Heap.h"

@interface User()


@end

@implementation User

// Request user from facebook and store it in userDefault
+ (void)fillUserDefaultfromFacebook
{
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSLog(@"Facebook public profile: %@", result);
            // Success! fill userDefaults
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

            [userDefaults setObject:result[@"id"] forKey:@"facebook_id"];
            [userDefaults setObject:result[@"email"] forKey:@"email"];
            [userDefaults setObject:result[@"first_name"] forKey:@"first_name"];
            [userDefaults setObject:result[@"last_name"] forKey:@"last_name"];
            [userDefaults setObject:result[@"gender"] forKey:@"gender"];
            [userDefaults setObject:result[@"link"] forKey:@"profile_link"];
            [userDefaults setObject:FBSession.activeSession.accessTokenData.accessToken forKey:@"token"];
            
            //post a notification to the init method
            [[NSNotificationCenter defaultCenter] postNotificationName:@"User Default Ready" object:nil];
        } else {
            NSLog(@"Error while retrieving user informations");
            // An error occurred, we need to handle the error
            // See: https://developers.facebook.com/docs/ios/errors
        }
    }];
}


//we alloc init the user only the first time thanks to the static variable
+ (User *)theUser
{
    static User *theUser = nil;
    if (!theUser) {
        // App just launched, we have user properties in local memory but theUser is not setup
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"facebook_id"]) {
            theUser = [[super allocWithZone:nil] init];

            // Send info to the backend
            [theUser sendUserInformationsWithParameter:[theUser fromUserToDictionary]];

        } else {
            //case : new user, session, app lauchwhen. userDefault is filled init the userObject
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theUser) name:@"User Default Ready" object:nil];
            [self fillUserDefaultfromFacebook];
        }
    }
    return theUser;
}

+ (id)allocWithZone:(NSZone *)zone{
    return [self theUser];
}

-(id) init
{
    self = [super init];
    if (self) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        self.id = [userDefaults objectForKey:@"id"];
        self.facebook_id = [userDefaults objectForKey:@"facebook_id"];
        self.first_name = [userDefaults objectForKey:@"first_name"];
        self.last_name = [userDefaults objectForKey:@"last_name"];
        self.name = [[self.first_name stringByAppendingString:@" "] stringByAppendingString: self.last_name];
        self.email = [userDefaults objectForKey:@"email"];
        if (!self.email) {
            self.email = [self.facebook_id stringByAppendingString:@"@facebook.com"];
        }
        self.token = [userDefaults objectForKey:@"token"];
        self.count_sweetch = [userDefaults objectForKey:@"count_sweetch"];
        self.cardNumber = [userDefaults objectForKey:@"cardNumber"];
        self.cardType = [userDefaults objectForKey:@"cardType"];
        self.gender = [userDefaults objectForKey:@"gender"];
        if (!self.gender) {
            self.gender = @"male";
        }
        self.isCustomer = [[userDefaults objectForKey:@"isCustomer"] boolValue];
    }
    return self;
}

- (NSDictionary *)fromUserToDictionary
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.facebook_id, @"facebook_id",
                                self.email, @"email",
                                self.first_name, @"first_name",
                                self.last_name, @"last_name",
                                self.gender, @"gender",
                                FBSession.activeSession.accessTokenData.accessToken, @"token",nil];
    return dictionary;
}

// Send the user Info to the backend
// Creates user or updates it, especially keep the facebook token up to date in the backend
- (void)sendUserInformationsWithParameter:(NSDictionary *)parameters
{
    NSLog(@"POST to back-end with: %@", parameters);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *baseURL = API_URL;
    NSString *url = [baseURL stringByAppendingString:@"/users"];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        NSLog(@"POST Response: %@", JSON);

        // Synchronise count sweetch
        [userDefaults setObject:[JSON[@"user"][@"count_sweetch"] stringValue] forKey:@"count_sweetch"];
        self.count_sweetch = [userDefaults objectForKey:@"count_sweetch"];

        // Set the id of the user in our database
        [userDefaults setObject:[JSON[@"user"][@"id"] stringValue] forKey:@"id"];
        self.id = [userDefaults objectForKey:@"id"];
        
        // Set number of credits
        [userDefaults setObject:[JSON[@"user"][@"credits"] stringValue] forKey:@"credits"];
        self.credits = [userDefaults objectForKey:@"credits"];
        
        // Set customer bool
        [userDefaults setObject:JSON[@"user"][@"is_customer"] forKey:@"isCustomer"];
        self.isCustomer = [JSON[@"user"][@"is_customer"] boolValue];
        
        // Set phone number
        self.phoneNumber = JSON[@"user"][@"phone"];
        [userDefaults setObject:self.phoneNumber forKey:@"phoneNumber"];
        
        // Check that we have card number and type if the user is already a customer
        if (self.isCustomer && self.cardNumber == nil) {
            self.cardNumber = [[NSString alloc] initWithFormat:@"•••%@",JSON[@"user"][@"card"][@"last4"]];
            self.cardType = JSON[@"user"][@"card"][@"type"];
            
            [userDefaults setObject:self.cardNumber forKey:@"cardNumber"];
            [userDefaults setObject:self.cardType forKey:@"cardType"];
        }
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        
        if (JSON[@"user"][@"created"]) {
            // Create alias -- links Mixpanel Distinct ID with the Sweetch user id
            [mixpanel createAlias:self.id forDistinctID:mixpanel.distinctId];
            NSLog(@"Alias created");
            // Associate all future events sent to the user id
            [mixpanel identify:self.id];
            // Create user with the user_id as distinct_id
            [mixpanel.people set:@{@"$email":self.email, @"$first_name": self.first_name, @"$last_name": self.last_name, @"$gender": self.gender, @"User ID": self.id, @"Signed up": @"1", @"Facebook": [NSString stringWithFormat:@"www.facebook.com/%@",self.facebook_id]}];
            
            // Identify on Heap
            
            NSString *name = [self.first_name stringByAppendingFormat:@" %@",self.last_name];
            NSDictionary* userProperties = @{
                                             @"name": name,
                                             @"email": self.email,
                                             @"handle": self.id,
                                             @"facebook": [NSString stringWithFormat:@"www.facebook.com/%@",self.facebook_id]
                                             };
            [Heap identify:userProperties];
        } else {
            // Associate all future events sent to the user id
            NSLog(@"Identify user with id");
            [mixpanel identify:self.id];
        }
        
        // For each session identify the Appsee user
        [Appsee setUserID:self.id];
        
        // Tell the app delegate that the User Object is fully instantiated
        self.ready = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserInstantiated" object:self];
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"NSError: %@",error.localizedDescription);
        
    }];
}

- (void)patchUserWithParameter:(NSDictionary *)changedParameters
{
    NSLog(@"PATCH /users/%@ with: %@",self.id, changedParameters);
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:changedParameters];
    [params setObject:self.token forKey:@"auth_token"];

    NSString *baseURL = API_URL;
    NSString *path = [NSString stringWithFormat:@"/users/%@",self.id];
    NSString *url = [baseURL stringByAppendingString:path];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager PUT:url parameters:changedParameters success:^(AFHTTPRequestOperation *operation, id JSON) {
            
        NSLog (@"User updated on back-end");
//        
//        // Synchronize count sweetch and credits
//        self.count_sweetch = JSON[@"count_sweetch"];
//        self.credits = JSON[@"credits"];
//        
//        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        [userDefaults setObject:self.count_sweetch forKey:@"count_sweetch"];
//        [userDefaults setObject:self.credits forKey:@"credits"];

        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdatedInBackend" object:self];
            
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           
        NSLog(@"NSError: %@",error.localizedDescription);
           
    }];
    
}

// Synchronize credits, count_sweetch, card_number
- (void)getUserFromBackend
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *baseURL = API_URL;
    NSString *path = [NSString stringWithFormat:@"/users/me?auth_token=%@",self.token];
    NSString *url = [baseURL stringByAppendingString:path];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        NSLog(@"Received user from back-end");

        // Update credits and count sweetch
        self.count_sweetch = JSON[@"count_sweetch"];
        self.credits = JSON[@"credits"];
        
        [userDefaults setObject:self.count_sweetch forKey:@"count_sweetch"];
        [userDefaults setObject:self.credits forKey:@"credits"];
        
        self.cardNumber = [[NSString alloc] initWithFormat:@"•••%@",JSON[@"card"][@"last4"]];
        self.cardType = JSON[@"card"][@"type"];
        
        NSLog(@"Card number: %@", self.cardNumber);
        NSLog(@"Card type: %@", self.cardType);
        
        [userDefaults setObject:self.cardNumber forKey:@"cardNumber"];
        [userDefaults setObject:self.cardType forKey:@"cardType"];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"NSError: %@",error.localizedDescription);
        
    }];
}

- (void)saveLocation
{
    if (self.location) {
        NSDictionary *params = @{@"auth_token":self.token,
                                 @"lat":[NSNumber numberWithDouble:self.location.coordinate.latitude],
                                 @"lng":[NSNumber numberWithDouble:self.location.coordinate.longitude]};
       
        NSString *baseURL = API_URL;
        NSString *path = [NSString stringWithFormat:@"/users/%@",self.id];
        NSString *url = [baseURL stringByAppendingString:path];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        [manager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
            
            NSLog(@"Location saved in backend");

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            NSLog(@"NSError: %@",error.localizedDescription);
            
        }];
    }
}

@end
