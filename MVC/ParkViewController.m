//
//  ViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 05/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//
#import "ParkViewController.h"
#import "Mixpanel.h"
#import "MBProgressHUD.h"
#import <Appsee/Appsee.h>
#import "Heap.h"

@interface ParkViewController ()

@property (strong, nonatomic) IBOutlet MKMapView *theMap;
@property (weak, nonatomic) IBOutlet UIButton *parkButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *leaveButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (strong, nonatomic) IBOutlet UIView *leaverView;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *leaverProfilePicture;
@property (weak, nonatomic) IBOutlet UILabel *leaverLabel;
@property (strong, nonatomic) IBOutlet UILabel *spotLabel;
@property (strong, nonatomic) IBOutlet UIButton *centerOnMeButton;
@property (strong, nonatomic) NSString *sweetchFailedMessage;
@property (strong, nonatomic) NSString *noSpotMessage;
@property (strong, nonatomic) NSString *neighborhoodMessage;

@property (weak, nonatomic) IBOutlet UILabel *contactingDrivers;
@property (strong, nonatomic) IBOutlet UILabel *contactingDriversBanner;
@property (strong, nonatomic) MapAnnotation *spotAnnotation;
@property (strong, nonatomic) MKRoute *route;
@property (strong, nonatomic) id<MKOverlay> routeOverlay;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property BOOL stopCenterOnUser;

@end

@implementation ParkViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    // Get nearest spots when we have user address, and send user location to backend
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveUserLocation) name:@"userLocationUpdated" object:nil];
    
    //Declare the MapView
    self.theMap = [[MKMapView alloc] initWithFrame: self.view.frame];
    self.theMap.delegate = self;
    self.theMap.showsUserLocation=YES;
    self.theMap.zoomEnabled=YES;
    self.theMap.rotateEnabled=YES;
    self.theMap.scrollEnabled=YES;
    self.theMap.userTrackingMode=MKUserTrackingModeFollow;
    [self.view addSubview:self.theMap];
    
    // Center map on the bro's house
    [self defaultMap];

    // Round button
    self.parkButton.layer.cornerRadius = 30.0f;

    
    //PUT ALL THE SUBVIEWS BEFORE THE MAP
    
    [self.view addSubview:self.parkButton];
    [self.view addSubview:self.centerOnMeButton];
    [self.view addSubview:self.leaverLabel];
    [self.view addSubview:self.spotLabel];
    [self.view addSubview:self.contactingDriversBanner];
    [self.view addSubview:self.contactingDrivers];
    
    
    // Keep the leave navbar button pointer in memory
    self.leaveButton = self.navigationItem.rightBarButtonItem;
    
    // Setup sidebarButton
    UIBarButtonItem *theSidebarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:0 target:self.revealViewController action:@selector(revealToggle:)];
    self.sidebarButton= theSidebarButton;
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // Recover the wording
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.contactingDrivers.text = [userDefaults objectForKey:@"contacting_drivers"];
    self.sweetchFailedMessage = [userDefaults objectForKey:@"sweetch_failed_parker"];
    self.noSpotMessage = [userDefaults objectForKey:@"no_spot"];
    self.neighborhoodMessage = [userDefaults objectForKey:@"warning_message"];
    
    // Set text banner with information
    self.spotLabel.text = self.neighborhoodMessage;
}

- (void)viewWillAppear:(BOOL)animated
{
    // If a Sweetch is happenning, then add observers for validation or failure
    if (self.sweetchInProgress) {
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sweetchFailed) name:@"Sweetch Failed" object:appDelegate];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(displayConfirmationView) name:@"Sweetch Validated" object:appDelegate];
    }
    
    // Load initial view execpt if the user go to help and does not send feedback
    if (!self.backFromHelp) {
        // Load initial view
        [self loadInitialView];
    }

    // Reset boolean value
    self.backFromHelp = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadInitialView
{
    NSLog(@"Loading initial view");
    // replace the help by the park button
    self.navigationItem.rightBarButtonItem = self.leaveButton;
    self.navigationItem.leftBarButtonItem = self.sidebarButton;
    
    //Everytime you load initial view, you need to show nearest spots around and to center on user
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getNearestSpots) name:@"reverseGeocodedLocation" object:nil];
    [self centerOnUser];
    
    //Initial Map
    [self.theMap setFrame:self.view.frame];
    [self.theMap setUserTrackingMode:MKUserTrackingModeFollow];
    
    if(_routeOverlay) {
        [self.theMap removeOverlay:_routeOverlay];
    }
    if (self.spotAnnotation) {
        [self.theMap removeAnnotations:self.theMap.annotations];
    }

    // Remove leaverView = the banner with name of leaver
    self.leaverView.hidden = YES;
    
    // show the park button and enable it
    self.parkButton.hidden = NO;
    self.centerOnMeButton.hidden = NO;
    self.parkButton.enabled = YES;
    self.parkButton.enabled = YES;
    self.leaveButton.enabled = YES;
    self.sidebarButton.enabled = YES;
    self.contactingDrivers.hidden = YES;
    self.contactingDriversBanner.hidden = YES;
    [self.activityView removeFromSuperview];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (self.retry) {
        self.retry = NO;
        [self park:nil];
    }
    
}

# pragma mark - MKMapViewDelegateProtocol

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    //Here
    [self.theMap selectAnnotation:self.theMap.userLocation animated:YES];
}

// delegate method called everytime the userLocation is updated
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    // Center for the first time user location is updated
    if (!self.stopCenterOnUser) {
        self.stopCenterOnUser = YES;
        [self centerOnUser];
    }
    
    if (userLocation.coordinate.latitude != 0.0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"userLocationUpdated" object:nil];
    }
    [self delayedReverseGeocodeLocation:self.theMap.userLocation.location.coordinate];
}

//Method called after addOverlay
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    [self.theMap deselectAnnotation:self.theMap.userLocation animated:YES];
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor blueColor];
    renderer.lineWidth = 4.0;
    return  renderer;
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

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // Get address from center coordinate
    // Only if we don't have the car location yet
//    if(self.parkButton.enabled)
//    {
//        [UIView animateWithDuration:0.3 animations:^() {
//            self.parkButton.alpha = 1;
//        }];
//    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    // Warn user that the address is being updated
//    if (self.parkButton.enabled && !self.sweetchInProgress)
//    {
//        [UIView animateWithDuration:0.3 animations:^() {
//            self.parkButton.alpha = 0;
//        }];
//    }
}

# pragma mark - MapKit

// Used to center the map when the view did load
- (void)centerOnUser
{
    double regionWidth = 1000;
    double regionHeight = 1600;
    MKCoordinateRegion userRegion = MKCoordinateRegionMakeWithDistance(self.theMap.userLocation.location.coordinate, regionWidth, regionHeight);
    [self.theMap setRegion:userRegion animated:YES];
    [self reverseGeocodeLocation:self.theMap.userLocation.location.coordinate];
}

- (void)defaultMap
{
    double regionWidth = 8000;
    double regionHeight = 8000;
    
    // Center on the bro's house!
    double lat = [@"37.749" doubleValue];
    double lng = [@"-122.419" doubleValue];
    
    CLLocationCoordinate2D defaultCoordinates = CLLocationCoordinate2DMake(lat, lng);
    MKCoordinateRegion startRegion = MKCoordinateRegionMakeWithDistance(defaultCoordinates, regionWidth, regionHeight);
    [self.theMap setRegion:startRegion animated:YES];
}

# pragma mark - CLGeocoder

- (void)delayedReverseGeocodeLocation:(CLLocationCoordinate2D)coordinate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self reverseGeocodeLocation:coordinate];
}

- (void)reverseGeocodeLocation:(CLLocationCoordinate2D)coordinate
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (placemarks.count) {
            NSDictionary *dictionary = [[placemarks objectAtIndex:0] addressDictionary];
            self.theMap.userLocation.title = [dictionary objectForKey:@"Name"];
            [User theUser].zipcode = [dictionary objectForKey:@"ZIP"];
            if ([User theUser].zipcode) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reverseGeocodedLocation" object:nil];
            }
        }
    }];
}

- (void)delayedReverseGeocodeSpot:(CLLocationCoordinate2D)coordinate {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self reverseGeocodeSpot:coordinate];
}

- (void)reverseGeocodeSpot:(CLLocationCoordinate2D)coordinate {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if(placemarks.count){
            NSDictionary *dictionary = [[placemarks objectAtIndex:0] addressDictionary];
            self.spotLabel.text = [NSString stringWithFormat:@"Drive to %@",[dictionary objectForKey:@"Name"]];
        }
    }];
}

# pragma mark - User.h

// Saves user location to backend
- (void)saveUserLocation
{
    // Remove observer so that this method is called only once
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"userLocationUpdated" object:nil];

    User *theUser = [User theUser];
    theUser.location = self.theMap.userLocation.location;
    [theUser saveLocation];
    
    // Send user location to Appsee
    double latitude = self.theMap.userLocation.location.coordinate.latitude;
    double longitude = self.theMap.userLocation.location.coordinate.longitude;
    float horizontalAccuracy = self.theMap.userLocation.location.horizontalAccuracy;
    float verticalAccuracy = self.theMap.userLocation.location.horizontalAccuracy;
    
    [Appsee setLocation:latitude longitude:longitude horizontalAccuracy:horizontalAccuracy verticalAccuracy:verticalAccuracy];
}

# pragma mark - Poll back-end for information

- (void)getNearestSpots
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reverseGeocodedLocation" object:nil];
    NSLog(@"Get nearest spots");
    
    [self.theMap removeAnnotations:self.theMap.annotations];
    
    NSString *baseURL = API_URL;
    NSString *url = [baseURL stringByAppendingString:@"/sweetches"];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSNumber *userLatitude = [[NSNumber alloc] initWithDouble:self.theMap.userLocation.location.coordinate.latitude];
    NSNumber *userLongitude = [[NSNumber alloc] initWithDouble:self.theMap.userLocation.location.coordinate.longitude];
    
    NSDictionary *params = @{@"lat":userLatitude,
                             @"lng":userLongitude,
                             @"auth_token":FBSession.activeSession.accessTokenData.accessToken,
                             @"zip":[User theUser].zipcode,
                             @"parker":@true};
    
    // Get the nearest spots
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSLog(@"Nearest spots: %@",JSON);
        for (id sweetch in JSON[@"results"]) {
            NSString *lat = sweetch[@"leaver_lat"];
            NSString *lng = sweetch[@"leaver_lng"];
            
            CLLocationCoordinate2D leaverCoordinate = CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue]);
            
            MapAnnotation *leaverAnnotation = [[MapAnnotation alloc] init];
            leaverAnnotation.coordinate = leaverCoordinate;
            
            [self.theMap addAnnotation:leaverAnnotation];
        }
        
        NSLog(@"%@",JSON[@"covered_area"]);
        if ([JSON[@"covered_area"] isEqualToNumber:@1]) {
            self.spotLabel.text = [NSString stringWithFormat:@"%lu spots around",(unsigned long)[JSON[@"results"] count]];
        } else {
            self.spotLabel.text = self.neighborhoodMessage;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"NSError: %@",error.localizedDescription);
    }];
}


# pragma mark - Park requested

- (void)sweetchFailed
{
    // Return to initial state
    self.sweetchInProgress = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    UIAlertView *alert= [[UIAlertView alloc] initWithTitle: @"Sorry" message: self.sweetchFailedMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Retry",nil];
    [alert show];
}

- (void)noSpot
{
    self.contactingDriversBanner.hidden = YES;
    self.contactingDrivers.hidden = YES;
    [self.activityView removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle: @"Sorry" message: self.noSpotMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Retry",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alert.title isEqualToString:@"Sorry"]) {
        if (buttonIndex == 1) {
            self.retry = YES;
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self loadInitialView];
    }else if ([alert.title isEqualToString:@"Turn on your notifications"]){
        if (buttonIndex == 1){
            NSUserDefaults* userDefaults=[NSUserDefaults standardUserDefaults];
            NSString* supportNumber =[userDefaults objectForKey:@"support_number"];
            NSString *phoneNumber = [supportNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSString *phoneURL = [NSString stringWithFormat:@"tel:%@",phoneNumber];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneURL]];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self loadInitialView];
    }
}

// Sends user location to backend and creates a park request
- (IBAction)park:(id)sender{
    //Ask the User to put his credit card if he is not customer yet
    if(![User theUser].isCustomer){
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AddPaymentViewController* addPaymentVC= [mainStoryBoard instantiateViewControllerWithIdentifier:@"AddPayment"];
        [self presentViewController:addPaymentVC animated:YES completion:nil];
    }else{
        // Send to Appsee
        [Appsee addEvent:@"Request Park"];

        // Remove older annotations
        if (self.spotAnnotation) {
            [self.theMap removeAnnotation:self.spotAnnotation];
        }

        //Disable the parkButton, navigation button, and relocate button
        self.parkButton.enabled = NO;
        self.leaveButton.enabled = NO;
        self.sidebarButton.enabled = NO;
        //self.centerOnMeButton.enabled = NO;

        // Show HUD
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        // Track activity to mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Request Park" properties:@{@"Address":self.theMap.userLocation.title}];
        [mixpanel.people increment:@"Park Requests" by:@1];

        // Send the user location to the backend and initiate a Sweetch
        NSNumber *userLatitude = [[NSNumber alloc] initWithDouble:self.theMap.userLocation.location.coordinate.latitude];
        NSNumber *userLongitude = [[NSNumber alloc] initWithDouble:self.theMap.userLocation.location.coordinate.longitude];

        NSMutableDictionary *dictionary= [[NSMutableDictionary alloc] initWithDictionary: @{@"parker_lat":userLatitude, @"parker_lng":userLongitude, @"address":self.theMap.userLocation.title, @"auth_token":FBSession.activeSession.accessTokenData.accessToken}];

        if ([User theUser].zipcode) {
            [dictionary setObject:[User theUser].zipcode forKey:@"zip"];
        }

        NSDictionary *parameters = [[NSDictionary alloc]initWithDictionary:dictionary];
        self.sweetch = [[Sweetch alloc] initWithParameters:parameters];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationNotSupported) name:@"locationNotSupported" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationsNotAllowed) name:@"notificationsNotAllowed" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displaySearchForDriverView) name:@"Sweetch Loaded" object:self.sweetch];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSweetch) name:@"Sweetch Completed" object:self.sweetch];
    }
   
}


# pragma mark - Errors

- (void)locationNotSupported
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                    message:[userDefaults objectForKey:@"wrong_neighborhood"]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)notificationsNotAllowed
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Turn on your notifications"
                                                    message:[userDefaults objectForKey:@"notifications_not_allowed"]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Call Support",nil];
    [alert show];
}



# pragma mark - Match waiting

-(void)displaySearchForDriverView{
    
    // Hide HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    // Hide park button and show banner
    self.parkButton.hidden = YES;
    self.centerOnMeButton.hidden = YES;
    self.contactingDrivers.hidden = NO;
    self.contactingDriversBanner.hidden = NO;
    
    // Set activity indicator in banner
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityView.center = self.view.center;
    CGPoint activityCenter = CGPointMake(35, self.view.frame.size.height - 45 - 71 / 2);
    self.activityView.center = activityCenter;
    
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
    
    // Replace the leave button by a CANCEL button and hide the left button
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelSweetch)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    // Listen for Match notifications
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSweetch:) name:@"Match Found" object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noSpot) name:@"Match Not Found" object:appDelegate];
}

- (void)callDriver
{
    NSString *phoneNumber = [NSString stringWithFormat:@"tel:%@",self.sweetch.leaver.phone];
    NSLog(@"%@",phoneNumber);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

// Revert to initial view when sweetch is canceled by parker
- (void)cancelSweetch
{
    // Remove observers for Match notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Come back to the initial view
    [self loadInitialView];
    
    // Track activity in Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Cancel Park"];
    [mixpanel.people increment:@"Cancel Requests" by:@1];
    
    // Track event
    [Heap track:@"Cancel Park"];

    // Send a mesage to the server
    self.sweetch.state = @"cancelled";
    [self.sweetch updateInBackend];
}

# pragma mark - Match found

- (void)didReceiveSweetch:(NSNotification *)notification
{
    NSLog(@"Match received through notification: %@", notification.userInfo);
    self.sweetch.lat = notification.userInfo[@"extra"][@"lat"];
    self.sweetch.lng = notification.userInfo[@"extra"][@"lng"];
    self.sweetch.leaver = [[Driver alloc] initWithDictionary: notification.userInfo[@"extra"]];
    self.sweetch.state = @"in_progress";
    
    [self showSweetch];
}

- (void)showSweetch
{
    // Send event to Heap
    [Heap track:@"Match found"];
    
    //remove all notations before showing the spot
    [self.theMap removeAnnotations:self.theMap.annotations];
    
    //Show information about the Leaver
    [self populateLeaverView:self.sweetch.leaver];
    
    //Adjust the Map
    [self adjustTheMap];
    
    // SHOW SPOT
    [self showSpot];
    
    // draw a direction from the userLocation to the spot and set the spotLabel.text
    [self drawRouteToSpot];
    
}


- (void)showSpot
{
    //add annotation from the spot dictionnary
    CLLocationCoordinate2D spotCoordinate = CLLocationCoordinate2DMake([self.sweetch.lat doubleValue], [self.sweetch.lng doubleValue]);

    self.spotAnnotation = [[MapAnnotation alloc] init];
    self.spotAnnotation.coordinate = spotCoordinate;
    
    [self.theMap addAnnotation:self.spotAnnotation];

    // Fill in spot address
    [self delayedReverseGeocodeSpot:self.sweetch.spotCoordinate];
}

# pragma mark - Draw directions

// assign the route to self.route, drawRouteToSpot and set the spotLabel.text
- (void)drawRouteToSpot
{
    NSLog(@"Sweetch lat %@",self.sweetch.lat);
   
    CLLocationCoordinate2D spotCoordinate = CLLocationCoordinate2DMake([self.sweetch.lat doubleValue], [self.sweetch.lng doubleValue]);
    MKPlacemark *destinationPlacemark= [[MKPlacemark alloc]initWithCoordinate:spotCoordinate addressDictionary:nil];
    MKMapItem *destination= [[MKMapItem alloc]initWithPlacemark:destinationPlacemark];
    
    MKDirectionsRequest *directionsRequest = [MKDirectionsRequest new];
    
    [directionsRequest setSource:[MKMapItem mapItemForCurrentLocation]];
    [directionsRequest setDestination:destination];
    
    directionsRequest.transportType = MKDirectionsTransportTypeAutomobile;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];

    self.route= [[MKRoute alloc]init];

    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        // Now handle the result
        
        if (error) {
            NSLog(@"There was an error getting your directions %@", error);
        }
        // So there wasn't an error - let's plot those routes
        self.route = [response.routes firstObject];
        
        
        if (self.route){
        [self plotRouteOnMapAndCenter];
       
         // when you have the route update the text Label via notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"route distance is available" object: self];
            
        }
        
    }];
  
}

- (void)plotRouteOnMapAndCenter
{
    if(_routeOverlay) {
        [self.theMap removeOverlay:_routeOverlay];
    }
    
    // Update the ivar
    _routeOverlay = self.route.polyline;
    
    //Ajust a new mapRect with the offset and transform it on a Region
    MKCoordinateRegion region= MKCoordinateRegionForMapRect([_routeOverlay boundingMapRect]);
    MKCoordinateRegion newRegion= MKCoordinateRegionMake(region.center, MKCoordinateSpanMake(1.4*region.span.latitudeDelta, region.span.longitudeDelta));
    [self.theMap setRegion:newRegion animated:YES];
    
    // Add it to the map
    [self.theMap addOverlay:_routeOverlay];
}

-(void) adjustTheMap {
    //Change the frame

    CGRect mapFrame = self.theMap.frame;
    mapFrame.size.height = self.theMap.frame.size.height -self.leaverView.frame.size.height;
    self.theMap.frame = mapFrame;
    //NSLog(@"After mapFrame size %f %f", self.theMap.frame.size.width, self.theMap.frame.size.height);
    
    //Change navigation Mode
    [self.theMap setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
}

# pragma mark - Switch to Sweetch view

// Display the leaver banner when a match is found
- (void)populateLeaverView:(Driver *)leaver
{
    // Remove observer for match not found
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Match Not Found" object:nil];

    // Memorize that a sweetch is in progress
    self.sweetchInProgress = YES;

    // Hide the parkButton
    self.parkButton.hidden = YES;
    self.centerOnMeButton.hidden = YES;
    self.contactingDrivers.hidden = YES;
    self.contactingDriversBanner.hidden = YES;
    [self.activityView removeFromSuperview];
    
    
    // Hide HUD
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    // Replace it by the LeaverView
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"LeaverView" owner:self options:nil];
    self.leaverView = [subviewArray objectAtIndex:0];
    CGRect bannerFrame = self.leaverView.frame;
    bannerFrame.size = self.leaverView.frame.size;
    bannerFrame.origin.x = 0;
    bannerFrame.origin.y = self.view.bounds.size.height - bannerFrame.size.height;
    self.leaverView.frame = bannerFrame;
    
    // Hide the navbar buttons
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    
    // Allow driver to be called if he has phone number
    if (self.sweetch.leaver.phone) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Call driver"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(callDriver)];
    }
    
    // Replace the park button by a help button
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(pushHelpViewController)];
    self.navigationItem.rightBarButtonItem = helpButton;

    // Profile pic : radius + profileID
    self.leaverProfilePicture.layer.cornerRadius = self.leaverProfilePicture.frame.size.width/2.0;
    self.leaverProfilePicture.profileID = leaver.facebook_id;

    // Instruction for parker
    NSString *gender = [User theUser].gender;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if ([gender isEqualToString:@"male"]) {
        NSString *instructionsMale = [userDefaults objectForKey:@"leaver_label_male"];
        NSString *instructions =  [instructionsMale stringByReplacingOccurrencesOfString:@"leaver_name" withString:self.sweetch.leaver.first_name];
        self.leaverLabel.text = instructions;
    } else {
        NSString *instructionsFemale = [userDefaults objectForKey:@"leaver_label_female"];
        NSString *instructions =  [instructionsFemale stringByReplacingOccurrencesOfString:@"leaver_name" withString:self.sweetch.leaver.first_name];
        self.leaverLabel.text = instructions;
    }

    [self.view addSubview:self.leaverView];

    // Notification either to display the confirmation view or you perform the sweetchFailed method
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(displayConfirmationView) name:@"Sweetch Validated" object:appDelegate];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sweetchFailed) name:@"Sweetch Failed" object:appDelegate];
}


# pragma mark - Exit park controller

- (void)displayConfirmationView
{
    // Return to normal state
    self.sweetchInProgress = NO;

    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ParkConfirmationViewController *parkConfirmationViewController= [mainStoryBoard instantiateViewControllerWithIdentifier:@"parkConfirmation"];
    parkConfirmationViewController.sweetch= self.sweetch;
    [self.navigationController pushViewController:parkConfirmationViewController animated:NO];
}

- (void)pushHelpViewController
{
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HelpViewController * helpViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"help"];
    helpViewController.sweetch = self.sweetch;
    helpViewController.calledFromPark = YES;
    helpViewController.calledFromParkConfirmation = NO;
    [self.navigationController pushViewController:helpViewController animated:YES];
}

- (IBAction)toLeaveVC:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Clicks leave screen"];
}

- (IBAction)centerOnMeTouched:(id)sender {
    [self.theMap setCenterCoordinate:self.theMap.userLocation.location.coordinate animated:YES];
}

- (void)dealloc
{
    self.theMap = nil;
}


@end
