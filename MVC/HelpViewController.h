//
//  HelpViewController.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 19/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParkViewController.h"
#import "Sweetch.h"

@interface HelpViewController : UIViewController

@property (strong, nonatomic) Sweetch *sweetch;

@property BOOL calledFromPark;
@property BOOL calledFromParkConfirmation;
@property BOOL calledFromLeave;

@end
