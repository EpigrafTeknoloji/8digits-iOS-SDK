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

#import "JSONKit.h"
#import "ASIFormDataRequest.h"

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
	
	if (self.visit.logging) {
		NSLog(@"8digits: Event %@ for %@ (%@) will trigger", self.value, self.key, self.hitCode ? self.hitCode : @"no-hitcode");
	}
	
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
	
	NSString *URLString = [NSString stringWithFormat:@"%@/event/create", self.visit.urlPrefix];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[request setPostValue:self.visit.authToken forKey:@"authToken"];
	[request setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[request setPostValue:self.visit.visitorCode forKey:@"visitorCode"];
	[request setPostValue:self.visit.sessionCode forKey:@"sessionCode"];
	[request setQueuePriority:NSOperationQueuePriorityVeryHigh];
	
	if (self.hit) {
		[request setPostValue:self.hitCode forKey:@"hitCode"];
	}
	
	[request setPostValue:self.key forKey:@"key"];
	[request setPostValue:self.value forKey:@"value"];
	
	[request setCompletionBlock:^(void){
		
		if (self.visit.logging) {
			NSLog(@"8digits: Event %@ for %@ (%@) did trigger", self.value, self.key, self.hitCode ? self.hitCode : @"no-hitcode");
		}
		
		if (self.hit) {
			[self.hit eventDidTrigger:self];
		}
		
		else {
			[self.visit eventDidTrigger:self];
		}
	}];
	
	[self.visit addRequest:request];
	ED_ARC_RELEASE(request);
	
}

@end

@implementation UIViewController (EDEventAdditions)

- (void)triggerEventWithValue:(NSString *)value forKey:(NSString *)key {
	EDEvent *event = ED_ARC_AUTORELEASE([[EDEvent alloc] initWithValue:value forKey:key hit:self.hit]);
	[event trigger];
}

@end
