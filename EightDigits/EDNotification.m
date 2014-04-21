//
//  EDNotification.m
//  8DigitsExample
//
//  Created by skizilkaya on 27.02.2014.
//  Copyright (c) 2014 skizilkaya. All rights reserved.
//

#import "EDNotification.h"
#import "ED_ARC.h"
#import "EDNetwork.h"
#import "EDVisit.h"
#import "EDNotificationView.h"

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


+ (EDNotification *) lastNotfication {
    static EDNotification *_lastNotifcation = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lastNotifcation = [[EDNotification alloc] init];
    });
    
    return _lastNotifcation;
}


- (id)initWithDictionary:(NSDictionary *)dict {
    self = [self init];
    if(self) {
        self.title          = dict[@"title"];
        self.details        = dict[@"details"];
        self.imageURL       = dict[@"image"];
        self.buttonText     = dict[@"buttonText"];
    }
    
    return self;
}



+ (void)checkAndShowNotifications {
    EDVisit *currentVisit = [EDVisit currentVisit];
    
    
    NSString *service = @"notification/check";
    
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:currentVisit.authToken, @"authToken",
                            currentVisit.visitorCode, @"visitorCode",
                            currentVisit.trackingCode, @"trackingCode",
                            currentVisit.sessionCode, @"sessionCode",nil];
    
    
    [[EDNetwork sharedInstance] getRequest:service params:params completionBlock:^(id responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if(code == 1) {
            EDNotification *lastNotification = [EDNotification lastNotfication];
            
            NSDictionary *dict = responseObject[@"notification"];
            EDNotification *notification = [[EDNotification alloc] initWithDictionary:dict];
            
            
            if(!lastNotification.title || !([lastNotification.title isEqualToString:notification.title] && [lastNotification.details isEqualToString:notification.details])) {
                
                lastNotification.title          = notification.title;
                lastNotification.details        = notification.details;
                lastNotification.imageURL       = notification.imageURL;
                lastNotification.buttonText     = notification.buttonText;
                EDNotificationView *notificationView = [[EDNotificationView alloc] initWithNotification:notification];
                [notificationView show];
            }
            ED_ARC_RELEASE(dict);
            ED_ARC_RELEASE(notification);
        }
    } failBlock:^(NSError *error) {
        
    }];
    
    
    
}
@end
