//
//  EDEvent.m
//  EightDigits
//
//  Created by Seyithan Teymur on 29/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDEvent.h"

#import "EDHit.h"
#import "EDHit_Internal.h"
#import "EDVisit.h"
#import "EDVisit_Internal.h"
#import "EDNotification.h"


#import "ED_ARC.h"

@interface EDEvent ()

@property (nonatomic, assign, readonly)	EDVisit	*visit;

@end

@implementation EDEvent

@synthesize hit			= _hit;

@synthesize value		= _value;
@synthesize key			= _key;

@synthesize timestamp	= _timestamp;

#if !__has_feature(objc_arc)
- (void)dealloc {
	
	[_value release];
	[_key release];
	[_timestamp release];
	
	[super dealloc];
	
}
#endif

#pragma mark - Custom accessor

- (NSString *)hitCode {
	return self.hit.hitCode;
}

- (EDVisit *)visit {
	if (self.hit) {
		return self.hit.visit;
	}
	
	return [EDVisit currentVisit];
}

#pragma mark - Init

- (id)init {
	
	self = [super init];
	
	if (self) {
		self.timestamp = [NSDate date];
	}
	
	return self;
	
}

- (id)initWithValue:(NSString *)value forKey:(NSString *)key {
	
	self = [self init];
	
	if (self) {
		self.key = key;
		self.value = value;
	}
	
	return self;
	
}

- (id)initWithValue:(NSString *)value forKey:(NSString *)key hit:(EDHit *)hit {
	
	self = [self initWithValue:value forKey:key];
	
	if (!hit.startDate) {
		return self;
	}
	
	if (self) {
		self.hit = hit;
	}
	
	return self;
	
}

- (void)trigger {
	
    [self.visit logMessage:@"Event %@ for %@ (%@) will trigger", self.value, self.key, self.hitCode ? self.hitCode : @"no-hitcode"];

	
	if (self.hit) {
		[self.hit eventWillTrigger:self];
		if (!self.hit.registered) {
			return;
		}
	}
	
	else {
		[self.visit eventWillTrigger:self];
		if (!self.visit.authorised) {
			return;
		}
	}
    NSString *service           = @"event/create";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.visit.authToken, @"authToken",
                                   self.visit.trackingCode, @"trackingCode",
                                   self.visit.visitorCode, @"visitorCode",
                                   self.visit.sessionCode, @"sessionCode",
                                   self.key, @"key",
                                   self.value, @"value",
                                   nil];
    if(self.hit) {
        [params setObject:self.hitCode forKey:@"hitCode"];
    }
    
    
    [[EDNetwork sharedInstance] postRequest:service params:params completionBlock:^(id responseObject) {
        
        [self.visit logMessage:@"Event %@ for %@ (%@) did trigger", self.value, self.key, self.hitCode ? self.hitCode : @"no-hitcode"];
		
		if (self.hit) {
			[self.hit eventDidTrigger:self];
		}
		
		else {
			[self.visit eventDidTrigger:self];
		}
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //code to be executed on the main queue after delay
           [EDNotification checkAndShowNotifications];
        });
        
        

    } failBlock:nil];
    
    ED_ARC_RELEASE(params);
	
}

@end

@implementation UIViewController (EDEventAdditions)

- (void)triggerEventWithValue:(NSString *)value forKey:(NSString *)key {
	EDEvent *event = ED_ARC_AUTORELEASE([[EDEvent alloc] initWithValue:value forKey:key hit:self.hit]);
	[event trigger];
}

@end
