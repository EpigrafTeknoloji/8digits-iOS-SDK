//
//  EDEvent.h
//  EightDigits
//
//  Created by Seyithan Teymur on 29/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EDHit;

@interface EDEvent : NSObject

/**
	The EDHit object associated to the event
	nil if the event is anonymous.
 */
@property (nonatomic, assign)			EDHit		*hit;

/**
	The hitCode of the event
	@returns self.hit.hitCode
	nil if the event is anonymous.
 */
@property (nonatomic, readonly, copy)	NSString	*hitCode;

- (id)initWithValue:(NSString *)value forKey:(NSString *)key hit:(EDHit *)hit;

/**
	Value of the event
	Must be non-nil when trigger is called.
 */
@property (nonatomic, copy)				NSString	*value;

/**
	Key of the event
	Must be non-nil when trigger is called.
 */
@property (nonatomic, copy)				NSString	*key;

- (id)initWithValue:(NSString *)value forKey:(NSString *)key;

/**
	Timestamp of the trigger
 */
@property (nonatomic, strong)			NSDate		*timestamp;

/**
	Triggers the event
	If the event is associated with a hit which has not registered yet, the event waits until the hit is registered, then triggers itself. 
	@warning The event might never get triggered if the hit to which it is associated never gets registered.
	If the event is anonymous, it will get triggered right away.
 */
- (void)trigger;

@end

@interface UIViewController (EDEventAdditions)

/**
	Creates and submits an event with given key-value pair
	The hitCode to be used with the event is self.hitCode which itself returns self.hit.hitCode. This means that the event that will be triggered will be associated with this controller. If you want to trigger anonymous (not associated with any screens) events, please see EDVisit instance method with the same name.
	@see -[EDVisit triggerEventWithValue:forKey:]
	@params value, key The key-value pair of the event.
 */
- (void)triggerEventWithValue:(NSString *)value forKey:(NSString *)key;

@end
