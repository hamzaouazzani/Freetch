//
//  Driver.h
//  MVC
//
//  Created by Hamza Ouazzani Chahdi on 10/03/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Driver : NSObject

@property (strong, nonatomic) NSString *facebook_id;
@property (strong, nonatomic) NSString *first_name;
@property (strong, nonatomic) NSString *phone;

-(id)initWithDictionary:(NSDictionary *)dictionary;
@end
