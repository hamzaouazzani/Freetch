//
//  LeaveConfirmationViewController.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 24/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LeaveViewController.h"
#import "AppDelegate.h"
#import "Sweetch.h"

@interface LeaveConfirmationViewController : UIViewController

@property (strong, nonatomic) Sweetch *sweetch;
@property CLLocationCoordinate2D carLocation;

@end
