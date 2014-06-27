//
//  PageContentViewController.m
//  MVC
//
//  Created by Thomas on 19/05/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "PageContentViewController.h"

@implementation PageContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundImageView.image = [UIImage imageNamed:self.imageFile];
    self.titleLabel.text = self.titleText;
}

@end
