//
//  LeaveViewController.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 09/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapAnnotation.h"
#import "LoginViewController.h"
#import "ParkViewController.h"
#import "LeaveConfirmationViewController.h"
#import "ProfileViewController.h"
#import "Sweetch.h"
#import "MBProgressHUD.h"
#import "Reachability.h"

@interface LeaveViewController : UIViewController

@property (strong, nonatomic) Sweetch *sweetch;
@property CLLocationCoordinate2D carLocation;
@property BOOL carLocationGiven;
@property BOOL retry;
@property BOOL okTapped;

@end
