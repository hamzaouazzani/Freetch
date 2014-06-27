//
//  LeaveViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 09/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "LeaveViewController.h"
#import "Mixpanel.h"
#import "Heap.h"

@interface LeaveViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *theMap;
@property (weak, nonatomic) IBOutlet UIButton *leaveButton;
@property (weak, nonatomic) IBOutlet UILabel *pinYourCarLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactingDrivers;
@property (weak, nonatomic) IBOutlet UIImageView *pin;
@property (strong, nonatomic) IBOutlet UIImageView *carAddressView;
@property (strong, nonatomic) IBOutlet UILabel *carAddressLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong, nonatomic) IBOutlet UIButton *centerOnMeButton;
@property (strong, nonatomic) UIBarButtonItem *parkButton;
@property (strong, nonatomic) UIBarButtonItem *sidebarButton;
@property (strong, nonatomic) NSString *noDriverMessage;
@property (strong, nonatomic) CLLocation* selectedLocation;
@property (strong, nonatomic) MapAnnotation *carAnnotation;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (strong,nonatomic) NSString * leaveAfterParkMessage;

@end

@implementation LeaveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get wording from app storage
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.contactingDrivers.text = [userDefaults objectForKey:@"contacting_parkers"];
    self.noDriverMessage = [userDefaults objectForKey:@"no_driver"];
    self.pinYourCarLabel.text = [userDefaults objectForKey:@"leave_instructions"];
    self.leaveAfterParkMessage = [userDefaults objectForKey:@"leave_instructions_after_park"];
    
    // Show user location on map
    self.theMap.showsUserLocation = YES;
    
    // Init Park button in navigation bar
    self.parkButton = [[UIBarButtonItem alloc] initWithTitle:@"Park" style:UIBarButtonItemStylePlain target:self action:@selector(goToParkFromNavbar)];
    
    // Init side menu in navigation bar
    UIBarButtonItem *theSidebarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:0 target:self.revealViewController action:@selector(revealToggle:)];
    self.sidebarButton = theSidebarButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self loadInitialView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Set up initial leave view
- (void)loadInitialView
{
    // Default setup
    self.navigationItem.rightBarButtonItem = self.parkButton;
    self.navigationItem.leftBarButtonItem = self.sidebarButton;
    self.leaveButton.hidden = NO;
    [self.leaveButton setEnabled:YES];
    [self.parkButton setEnabled:YES];
    [self.sidebarButton setEnabled:YES];
    self.contactingDrivers.hidden = YES;
    self.progressBar.hidden = YES;

    // Remove previous observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Remove spinning wheel
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self.activityView removeFromSuperview];
    
    // Remove annotation if it still is there
    [self.theMap removeAnnotation:self.carAnnotation];

    // We don't have the user's car location
    if (!self.carLocationGiven)
    {
        [self centerOnUser];

        // Pin and locateButton
        self.pin.hidden = NO;
        self.carAddressLabel.hidden = NO;
        self.carAddressView.hidden = NO;
        
        // Set instructions
        self.pinYourCarLabel.text = @"Pin your car";

    } else {
        // Drop the car pin
        self.carAnnotation = [[MapAnnotation alloc] init];
        self.carAnnotation.coordinate = self.carLocation;
        [self.theMap addAnnotation:self.carAnnotation];
        
        // Update the car address
        self.selectedLocation = [[CLLocation alloc] initWithLatitude:self.carLocation.latitude longitude:self.carLocation.longitude];
        [self reverseGeocodeLocation];
        
        // Hide the Sweetch pin and message
        self.pin.hidden = YES;
        self.carAddressLabel.hidden = YES;
        self.carAddressView.hidden = YES;
        self.pinYourCarLabel.text=self.leaveAfterParkMessage;
        [self centerOnCar];
    }

    // Retry to leave
    if (self.retry) {
        self.retry = NO;
        [self giveSpot:nil];
    }
}

# pragma mark - MKMapView Delegate Protocol

// Update address when user moves map
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // Get address from center coordinate
    // Only if we don't have the car location yet
    if(!self.carLocationGiven)
    {
        self.selectedLocation = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude
                                                           longitude:mapView.centerCoordinate.longitude];
        [self performSelector:@selector(delayedReverseGeocodeLocation)
               withObject:nil
               afterDelay:0.3];
        [UIView animateWithDuration:0.3 animations:^() {
            self.carAddressView.alpha = 1;
        }];
        [UIView animateWithDuration:0.3 animations:^() {
            self.carAddressLabel.alpha = 1;
        }];
        
        [UIView animateWithDuration:0.3 animations:^() {
            self.leaveButton.alpha = 1;
        }];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    // Warn user that the address is being updated
    if (!self.carLocationGiven)
    {
        [UIView animateWithDuration:0.3 animations:^() {
            self.carAddressView.alpha = 0;
        }];
        [UIView animateWithDuration:0.3 animations:^() {
            self.carAddressLabel.alpha = 0;
        }];
        
        [UIView animateWithDuration:0.3 animations:^() {
            self.leaveButton.alpha = 0;
        }];
    }
}

// Change the view for the leaver positions
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKAnnotationView *view = [self.theMap
                              dequeueReusableAnnotationViewWithIdentifier:@"annoView"];
    if(!view) {
        view = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                            reuseIdentifier:@"annoView"];
    }
    
    view.image = [UIImage imageNamed:@"carPin.png"];
    view.centerOffset = CGPointMake(6, -23);
    
    return view;
}

# pragma mark - MKMapView

- (void)delayedReverseGeocodeLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self reverseGeocodeLocation];
}

- (void)reverseGeocodeLocation
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
   [geocoder reverseGeocodeLocation:self.selectedLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if(placemarks.count) {
            NSDictionary *dictionary = [[placemarks objectAtIndex:0] addressDictionary];
            [User theUser].zipcode = [dictionary objectForKey:@"ZIP"];
            self.carAddressLabel.text = [dictionary objectForKey:@"Name"];
        }
   }];
}

// Center the map on user
- (void)centerOnUser
{
    double regionWidth = 500;
    double regionHeight = 500;
    MKCoordinateRegion startRegion = MKCoordinateRegionMakeWithDistance(self.theMap.userLocation.location.coordinate, regionWidth, regionHeight);
    [self.theMap setRegion:startRegion animated:YES];
}

- (void)centerOnCar
{
    MKCoordinateSpan span = MKCoordinateSpanMake(3*fabs(self.theMap.userLocation.location.coordinate.latitude - self.carLocation.latitude),3*fabs(self.theMap.userLocation.location.coordinate.longitude - self.carLocation.longitude));

    MKCoordinateRegion startRegion = MKCoordinateRegionMake(self.carLocation, span);
    [self.theMap setRegion:startRegion animated:YES];
}

# pragma mark - Navigation links

- (void)goToParkFromNavbar
{
    // Track activity in Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Clicks on Park screen"];

    [self.navigationController popToRootViewControllerAnimated:YES];
}

# pragma mark - Leave requested

// POST a sweetch to back-end with user information and location
- (IBAction)giveSpot:(id)sender
{
    if(![User theUser].isCustomer){
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AddPaymentViewController* addPaymentVC= [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddPayment"];
        [self presentViewController:addPaymentVC animated:YES completion:nil];
    } else {
        // Disable the leave button
        [self.leaveButton setEnabled:NO];
        [self.parkButton setEnabled:NO];
        [self.sidebarButton setEnabled:NO];
        [self.centerOnMeButton setEnabled:NO];

        // Show spinning wheel until response
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        // Hide car address bubble
        self.carAddressView.hidden = YES;
        self.carAddressLabel.hidden = YES;
        
        // Set car location
        self.carLocationGiven = YES;
        self.carLocation = self.theMap.centerCoordinate;
        
        // Change instructions to car address
        self.pinYourCarLabel.text = [NSString stringWithFormat:@"Parked at %@",self.carAddressLabel.text];
        
        // Track activity to Mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Request Leave" properties:@{@"Address":self.carAddressLabel.text, @"Zipcode":[User theUser].zipcode}];
        [mixpanel.people increment:@"Leave Requests" by:@1];
        
        // Send the location to the backend
        NSNumber *pinLatitude = [[NSNumber alloc] initWithDouble:self.carLocation.latitude];
        NSNumber *pinLongitude = [[NSNumber alloc] initWithDouble:self.carLocation.longitude];
        
        NSDictionary *theParameters = @{@"leaver_lat":pinLatitude, @"leaver_lng":pinLongitude, @"address":self.carAddressLabel.text, @"zip":[User theUser].zipcode, @"auth_token":FBSession.activeSession.accessTokenData.accessToken};
        
        self.sweetch = [[Sweetch alloc] initWithParameters:theParameters];
        
        // Not in the good neighborhood
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationNotSupported) name:@"locationNotSupported" object:nil];
        // No match found yet
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displaySearchForDriverView) name:@"Sweetch Loaded" object:self.sweetch];
        // Match found already
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLeaveConfirmation) name:@"Sweetch Completed" object:self.sweetch];
    }
}

- (void)locationNotSupported
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                    message:@"Sweetch is only available in the Mission District."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

// Removes initial view objects and puts banner
- (void)displaySearchForDriverView
{
    // Remove HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    // Set banner
    self.leaveButton.hidden = YES;
    self.centerOnMeButton.hidden = YES;
    self.contactingDrivers.hidden = NO;
    self.pin.hidden = YES;
    
    // Start progress bar
    self.progressBar.hidden = NO;
    self.progressBar.progress = 0.0;
    [self performSelectorOnMainThread:@selector(makeProgressBarMoving) withObject:nil waitUntilDone:NO];
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
    
    // Put a pin on the Map
    if (!self.carAnnotation) {
        self.carAnnotation = [[MapAnnotation alloc] init];
        self.carAnnotation.coordinate = self.carLocation;
        [self.theMap addAnnotation:self.carAnnotation];
    }
        
    //update the label with the car location
    [self reverseGeocodeLocation];
    
    // Hide the leaveButton
    
    
    // Replace the park button by a CANCEL button and hide the sidemenu
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelSweetch)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    // Listen for Match notifications
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveParker:) name:@"Match Found" object: appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noParker) name:@"Match Not Found" object: appDelegate];
}

- (void)makeProgressBarMoving
{
    float actual = [self.progressBar progress];
    float total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"waiting_time"] floatValue];
    if (actual < 1) {
        self.progressBar.progress = actual + 0.05/(total * 60);
        
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(makeProgressBarMoving) userInfo:nil repeats:NO];
    }
}

// Revert to initial view when sweetch is canceled by leaver
- (void)cancelSweetch
{
    // Remove observers for Match notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Remove annotation
    [self.theMap removeAnnotation:self.carAnnotation];
    self.carAnnotation = nil;
    
    // Come back to the initial view
    self.carLocationGiven = NO;
    [self loadInitialView];
    
    // Track activity in Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Cancel Leave"];
    [mixpanel.people increment:@"Cancel Requests" by:@1];
    
    // Cancel Leave
    [Heap track:@"Cancel Leave"];

    // Send a mesage to the server
    self.sweetch.state = @"cancelled";
    [self.sweetch updateInBackend];
}

// Show parker information and ETA when match found
- (void)didReceiveParker:(NSNotification *)notification
{
    NSLog(@"user info in notification %@", notification.userInfo);

    self.sweetch.parker = [[Driver alloc] initWithDictionary: notification.userInfo[@"extra"]];
    self.sweetch.eta = notification.userInfo[@"extra"][@"eta"];
    self.sweetch.state = notification.userInfo[@"extra"][@"state"];
    [self showLeaveConfirmation];
}

- (void)showLeaveConfirmation
{
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LeaveConfirmationViewController *leaveConfirmationVC = [mainStoryBoard instantiateViewControllerWithIdentifier:@"leaveConfirmation"];
    leaveConfirmationVC.sweetch = self.sweetch;
    leaveConfirmationVC.carLocation = self.carLocation;
    [self.navigationController pushViewController:leaveConfirmationVC animated:YES];
}

// Show pop-up message when no match found
- (void)noParker
{
    self.contactingDrivers.hidden = YES;
    [self.activityView removeFromSuperview];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Sorry" message:self.noDriverMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Retry",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        [self loadInitialView];
    } else if (buttonIndex == 1) {
        self.retry = YES;
    }
    [self loadInitialView];
}

- (IBAction)centerOnMeTouched:(id)sender {
    [self.theMap setCenterCoordinate:self.theMap.userLocation.location.coordinate animated:YES];
}

@end
