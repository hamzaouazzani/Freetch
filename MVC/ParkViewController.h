//
//  ViewController.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 05/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AFHTTPRequestOperationManager.h"
#import "MapAnnotation.h"
#import "LoginViewController.h"
#import "HelpViewController.h"
#import "ParkConfirmationViewController.h"
#import "LeaveViewController.h"
#import "Sweetch.h"
#import "Reachability.h"


@interface ParkViewController : UIViewController<MKMapViewDelegate>

@property (strong, nonatomic) Sweetch *sweetch;
@property BOOL backFromHelp;
@property BOOL sweetchInProgress;
@property BOOL retry;

- (void)displayConfirmationView;
- (void)getNearestSpots;

@end
