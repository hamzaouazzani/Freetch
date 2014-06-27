//
//  SupportViewController.h
//  MVC
//
//  Created by Thomas on 24/05/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"


@interface SupportViewController : UIViewController

- (IBAction)callSupport:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *TOSButton;

@end
