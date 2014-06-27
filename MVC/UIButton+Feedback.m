//
//  UIButton+Feedback.m
//  MVC
//
//  Created by Thomas on 22/02/2014.
//  Copyright (c) 2014 Hamza Ouazzani Chahdi. All rights reserved.
//

#import "UIButton+Feedback.h"
#include <objc/runtime.h>

@implementation UIButton (Feedback)

static char UIB_PROPERTY_KEY;

/* Use @dynamic to tell the compiler you're handling the accessors yourself. */
@dynamic feedback_id;

-(void)setFeedback_id:(NSNumber *)feedback_id
{
    objc_setAssociatedObject(self, &UIB_PROPERTY_KEY, feedback_id, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSNumber *)feedback_id
{
    return (NSNumber *)objc_getAssociatedObject(self, &UIB_PROPERTY_KEY);
}

@end
