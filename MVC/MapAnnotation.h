//
//  MapAnnotation.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 20/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

@end
