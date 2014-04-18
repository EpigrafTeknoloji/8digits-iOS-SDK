//
//  EDView.h
//  8DigitsExample
//
//  Created by skizilkaya on 27.02.2014.
//  Copyright (c) 2014 skizilkaya. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EDNotification;

@interface EDNotificationView : UIView

- (id)      initWithNotification:(EDNotification *) notification;
- (void)    show;
- (void)    hide;

@end
