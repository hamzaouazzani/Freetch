//
//  Sweetch.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "AFHTTPRequestOperationManager.h"
#import "Driver.h"

@interface Sweetch : NSObject
@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSString *eta;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSNumber *feedback_id;
//We need lat and lng to pin when the driver parked
@property (strong, nonatomic) NSString *lat;
@property (strong, nonatomic) NSString *lng;
@property (strong, nonatomic) Driver *parker;
@property (strong, nonatomic) Driver *leaver;

- (CLLocationCoordinate2D)spotCoordinate;
- (id)initWithParameters:(NSDictionary *)parameters;
- (void)updateInBackend;

@end
