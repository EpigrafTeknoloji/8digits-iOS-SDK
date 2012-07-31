//
//  EDHit_Internal.h
//  EightDigits
//
//  Created by Seyithan Teymur on 29/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDHit.h"

@class EDEvent;

@interface EDHit ()

- (void)eventWillTrigger:(EDEvent *)event;
- (void)eventDidTrigger:(EDEvent *)event;

@end
