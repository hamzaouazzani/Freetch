//
//  Driver.m
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "Driver.h"

@implementation Driver

-(id)init
{
    self = [super init];
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.first_name = dictionary[@"first_name"];
        self.facebook_id = dictionary[@"facebook_id"];
        self.phone = dictionary[@"ph"];
     }
    return self;
}

@end
