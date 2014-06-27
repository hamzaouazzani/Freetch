//
//  ProfileViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 06/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "Mixpanel.h"
#import "MBProgressHUD.h"

@interface LoginViewController ()

@property (strong,nonatomic) NSDictionary *parameter;
@property NSUInteger actualIndex;

- (IBAction)performLogin:(id)sender;

@end

@implementation LoginViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Titles and images to display in onboarding flow
    _pageTitles = @[@"Find on-street parking in one tap.", @"Reward $5 the Sweetch buddy who gives you his spot.", @"5 mins before leaving, list your spot and get $4 back."];
    
    if (self.view.frame.size.height == 480) {
        _pageImages = @[@"screen1Small.png", @"screen2Small.png", @"screen3Small.png"];
    } else if (self.view.frame.size.height == 568) {
        _pageImages = @[@"screen1.png", @"screen2.png", @"screen3.png"];
    }
    
    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageViewController.dataSource = self;
    self.actualIndex =0;
    PageContentViewController *startingViewController = [self viewControllerAtIndex:self.actualIndex];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 70);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    //Customize the FBLoginButton
    [self changeButtonRegardingIndex];

}

- (void) viewWillDisappear:(BOOL)animated{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (IBAction)performLogin:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Logging in";
    
    // Track log in in Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Sign up"];

    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.newSession = YES;
    [appDelegate openFbSession];
}


-(void)changeButtonRegardingIndex{
    //Show button only for the last screen
    if (self.actualIndex == [self.pageTitles count]-1) {
        self.loginButton.hidden=NO;
        self.nextButton.hidden=YES;
    }else{
        self.loginButton.hidden=YES;
        self.nextButton.hidden=NO;
    }
}
- (IBAction)nextClicked:(id)sender {
    self.actualIndex++;
    NSArray *viewControllers = @[[self viewControllerAtIndex:self.actualIndex]];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self changeButtonRegardingIndex];
    
}
#pragma mark - Page View Controller Data Source

- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];
    pageContentViewController.imageFile = self.pageImages[index];
    pageContentViewController.titleText = self.pageTitles[index];
    pageContentViewController.pageIndex = index;
    
    return pageContentViewController;
}



- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    //Customize the FBLoginButton
    [self changeButtonRegardingIndex];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    self.actualIndex=index;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    //Customize the FBLoginButton
    [self changeButtonRegardingIndex];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    self.actualIndex=index;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return self.actualIndex;
}

@end
