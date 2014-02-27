//
//  EDNotification.m
//  8DigitsExample
//
//  Created by skizilkaya on 27.02.2014.
//  Copyright (c) 2014 skizilkaya. All rights reserved.
//

#import "EDNotification.h"
#import "ED_ARC.h"

@implementation EDNotification

- (void) dealloc {
    ED_ARC_RELEASE(self.title);
    ED_ARC_RELEASE(self.details);
    ED_ARC_RELEASE(self.imageURL);
    ED_ARC_RELEASE(self.buttonText);
    
    self.title      = nil;
    self.details    = nil;
    self.imageURL   = nil;
    self.buttonText = nil;
}

@end
