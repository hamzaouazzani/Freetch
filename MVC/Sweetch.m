//
//  Sweetch.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "Sweetch.h"

@implementation Sweetch

- (id)init
{
    self = [super init];
    return self;
}

- (id)initWithParameters:(NSDictionary *)parameters
{
    self = [super init];
    
    if (self) {
        NSString *baseURL = API_URL;
        NSString *url = [baseURL stringByAppendingString:@"/sweetches"];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
            
            NSLog(@"Sweetch %@", JSON[@"sweetch"]);
            self.id = JSON[@"sweetch"][@"id"];
            self.state = JSON[@"sweetch"][@"state"];
            
            if (JSON[@"error"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"No Spot" object:self];
            } else if ([self.state isEqualToString:@"in_progress"]) {
                self.parker = [[Driver alloc] initWithDictionary:@{@"facebook_id":JSON[@"sweetch"][@"parker_facebook_id"],
                                                                   @"first_name":JSON[@"sweetch"][@"parker_first_name"],
                                                                   @"ph":JSON[@"sweetch"][@"parker_ph"]}];
                self.leaver = [[Driver alloc] initWithDictionary:@{@"facebook_id":JSON[@"sweetch"][@"leaver_facebook_id"],
                                                                   @"first_name":JSON[@"sweetch"][@"leaver_first_name"],
                                                                   @"ph":JSON[@"sweetch"][@"leaver_ph"]}];
                self.eta = JSON[@"sweetch"][@"eta"];
                self.lat = JSON[@"sweetch"][@"lat"];
                self.lng = JSON[@"sweetch"][@"lng"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Sweetch Completed" object:self];
                
            } else if ([self.state isEqualToString:@"pending"]) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Sweetch Loaded" object:self];
            }

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            NSInteger statusCode = operation.response.statusCode;
            NSLog(@"NSError: %@",error.localizedDescription);
            if (statusCode == 417) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"locationNotSupported" object:nil];
            } else if(statusCode == 424) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"notificationsNotAllowed" object:nil];
            }
            
        }];
    }
    
    return self;
}

-(CLLocationCoordinate2D)spotCoordinate
{
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lng doubleValue]);
}

- (void)updateInBackend
{
    NSDictionary *defaultParams = @{@"auth_token":FBSession.activeSession.accessTokenData.accessToken,
                                 @"state":self.state};
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:defaultParams];
    
    if ([self.state isEqualToString:@"failed"]) {
        [parameters setObject:self.feedback_id forKey:@"feedback_id"];
    }
    
    NSString *baseURL = API_URL;
    NSString *path = [NSString stringWithFormat:@"/sweetches/%@",self.id];
    NSString *url = [baseURL stringByAppendingString:path];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Update the Sweetch with the new parameters
    [manager PUT:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        // Send the notification to update the User
        if ([JSON[@"sweetch"][@"state"] isEqualToString:@"validated"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Sweetch Validated" object:self];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"NSError: %@",error.localizedDescription);
    }];
}

@end
