//
//  PaymentViewController.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 17/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "PaymentViewController.h"
#import "Heap.h"

@interface PaymentViewController ()

@property (weak, nonatomic) NSString *cardCell;
@property (weak, nonatomic) NSString *addCell;

@end

@implementation PaymentViewController {
    NSMutableArray *cells;
    NSMutableArray *cellsImage;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Track event
    [Heap track:@"View payment"];

    // Setup the sidebar button
    UIBarButtonItem *sidebarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu.png"] style:0 target:self.revealViewController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = sidebarButton;

    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];

}

-(void) viewWillAppear:(BOOL)animated
{
    User *theUser = [User theUser];
    
    if(!theUser.isCustomer) {
        // Card has never been registered, the user has to
        self.cardCell = @"No credit card registered";
        self.addCell = @"Add a card";
    } else {
//        self.cardCell = [[NSUserDefaults standardUserDefaults] objectForKey:@"cardNumber"];
        self.cardCell = theUser.cardNumber;
        NSLog(@"card cell %@", self.cardCell);
        self.addCell = @"Change your card";
    }
    
    cells = [NSMutableArray arrayWithObjects:self.cardCell, self.addCell, nil];
    NSString *cardType = [self getCardTypeName];
    NSLog(@"Card Type: %@",cardType);
    cellsImage = [NSMutableArray arrayWithObjects:[self getCardTypeName],@"Add", nil];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section==0)
    {
        return [cells count];
    } else {
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.section ==0){
    NSString *cellIdentifier= [cells objectAtIndex:indexPath.row];
    UIImage *cellImage= [UIImage imageNamed:[NSString stringWithFormat:@"%@",[cellsImage objectAtIndex:indexPath.row]]];
    cell.textLabel.text= cellIdentifier;
    cell.imageView.image = cellImage;
    } else {
        cell.textLabel.text= [NSString stringWithFormat:@"Available Credits:                     $%@", [User theUser].credits];
    }
    
    return cell;
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    // Set the title of navigation bar by using the menu items
//    if ([segue.identifier isEqualToString:@"ChangeCard"]) {
//        AddPaymentViewController *destViewController = (AddPaymentViewController *)segue.destinationViewController;
//        destViewController.changeCard = YES;
//    }
//}

- (NSString *)getCardTypeName
{
    NSString *cardType = [[NSUserDefaults standardUserDefaults] objectForKey:@"cardType"];

    if (!cardType) {
        cardType = @"placeholder";
    }
    
    if ([cardType isEqualToString:@"American Express"]) {
        cardType = @"amex";
    } else if ([cardType isEqualToString:@"Visa"]) {
        cardType = @"visa";
    } else if ([cardType isEqualToString:@"MasterCard"]) {
        cardType = @"mastercard";
    } else if ([cardType isEqualToString:@"Discover"]) {
        cardType = @"discover";
    } else if ([cardType isEqualToString:@"Diners Club"]) {
        cardType = @"diners";
    } else if ([cardType isEqualToString:@"JCB"]) {
        cardType = @"jcb";
    }

    return cardType;
}

@end
