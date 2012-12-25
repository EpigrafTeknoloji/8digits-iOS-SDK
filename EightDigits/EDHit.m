//
//  EDHit.m
//  EightDigits
//
//  Created by Seyithan Teymur on 24/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import <objc/runtime.h>

#import "EDHit.h"
#import "EDHit_Internal.h"

#import "EDVisit.h"
#import "EDVisit_Internal.h"
#import "EDEvent.h"
#import "EDMonitor.h"

#import "ASIFormDataRequest.h"
#import "JSONKit.h"

#import "ED_ARC.h"

@interface EDHit ()

@property (nonatomic, strong, readwrite)			NSString			*hitCode;

@property (nonatomic, readwrite)					BOOL				 registered;
@property (nonatomic, getter = isCurrentlyValid)	BOOL				 currentlyValid;

@property (nonatomic, strong)						NSMutableArray		*eventArray;

@property (nonatomic, strong, readwrite)			NSDate				*startDate;
@property (nonatomic, strong, readwrite)			NSDate				*endDate;

@property (nonatomic, strong)						ASIFormDataRequest	*startRequest;
@property (nonatomic, strong)						ASIFormDataRequest	*endRequest;

- (void)requestStart;
- (void)requestEnd;

@end

@implementation EDHit

@synthesize visit					= _visit;
@synthesize hitCode					= _hitCode;

@synthesize title					= _title;
@synthesize path					= _path;

@synthesize registered				= _registered;
@synthesize currentlyValid			= _currentlyValid;

@synthesize events					= _events;
@synthesize eventArray				= _eventArray;

@synthesize startDate				= _startDate;
@synthesize endDate					= _endDate;

@synthesize startRequest			= _startRequest;
@synthesize endRequest				= _endRequest;

#if !__has_feature(objc_arc)
- (void)dealloc {
	
	[_hitCode release];
	
	[_title release];
	[_path release];
	
	[_eventArray release];

	[_startDate release];
	[_endDate release];
	
	[_startRequest release];
	[_endRequest release];
	
	[super dealloc];
	
}
#endif

#pragma mark - Initializer

- (id)initWithController:(UIViewController *)controller {
	
	self = [self init];
	
	if (self) {
		[self setTitle:controller.title path:NSStringFromClass(controller.class)];
	}
	
	return self;
	
}

- (id)init {
	
	self = [super init];
	
	if (self) {
		_eventArray = [[NSMutableArray alloc] init];
	}
	
	return self;
	
}

#pragma mark - Custom accessor

- (NSString *)hitCode {
	
	if (_hitCode == nil) {
		NSInteger hitCodeValue = arc4random() % NSIntegerMax;
		NSString *hitCode = [NSString stringWithFormat:@"%i", hitCodeValue];
		_hitCode = ED_ARC_RETAIN(hitCode);
	}
	
	return _hitCode;
	
}

- (EDVisit *)visit {
	if (!_visit) {
		return [EDVisit currentVisit];
	}
	
	return _visit;
}

- (NSArray *)events {
	return (NSArray *)self.eventArray;
}

- (void)setTitle:(NSString *)title path:(NSString *)path {
	self.title = title;
	self.path = path;
}

#pragma mark - Start stop

- (void)start {
	
	if (self.visit.logging) {
		NSLog(@"8digits: Hit %@ (%@) will start", self.path, self.hitCode);
	}
	
	[self setRegistered:NO];
	[self setStartDate:[NSDate date]];
	[self requestStart];
	
	[self.visit hitWillStart:self];
	
}

- (void)end {
	
	if (self.visit.logging) {
		NSLog(@"8digtis: Hit %@ (%@) will end", self.path, self.hitCode);
	}
	
	[self setEndDate:[NSDate date]];
	
	if (!self.registered || self.events.count) {
		return;
	}
	
	[self requestEnd];
	[self.visit hitWillEnd:self];
	
}

- (void)requestStart {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/hit/create", self.visit.urlPrefix];
	
	ED_ARC_RELEASE(_startRequest);
	
	_startRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[_startRequest setPostValue:self.visit.authToken forKey:@"authToken"];
	[_startRequest setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[_startRequest setPostValue:self.visit.visitorCode forKey:@"visitorCode"];
	[_startRequest setPostValue:self.visit.sessionCode forKey:@"sessionCode"];
	[_startRequest setPostValue:self.title forKey:@"pageTitle"];
	[_startRequest setPostValue:self.path forKey:@"path"];
	[_startRequest setPostValue:self.hitCode forKey:@"hitCode"];
	
	__unsafe_unretained EDHit *selfHit = self;
	
	[_startRequest setCompletionBlock:^(void) {
		
		if (self.visit.logging) {
			NSLog(@"8digits: Hit %@ (%@) did start", self.path, self.hitCode);
		}

		NSDictionary *dict = [self.startRequest.responseString objectFromJSONString];
		self.hitCode = [[dict objectForKey:@"data"] objectForKey:@"hitCode"];
		
		self.registered = YES;
		[self.visit hitDidStart:selfHit];
		
		[self.eventArray makeObjectsPerformSelector:@selector(trigger)];
		
	}];
	
	[_startRequest setFailedBlock:^(void){
		if (self.visit.logging) {
			NSLog(@"8digits: Hit %@ (%@) did fail to start: %@", self.path, self.hitCode, self.startRequest.error.localizedDescription);
		}
	}];
	
	[_startRequest setQueuePriority:self.events.count > 0 ? NSOperationQueuePriorityVeryHigh : NSOperationQueuePriorityHigh];
	[self.visit addRequest:self.startRequest];
	
}

- (void)requestEnd {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/hit/end", self.visit.urlPrefix];
	
	ED_ARC_RELEASE(_endRequest);
	
	_endRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[_endRequest setPostValue:self.visit.authToken forKey:@"authToken"];
	[_endRequest setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[_endRequest setPostValue:self.visit.visitorCode forKey:@"visitorCode"];
	[_endRequest setPostValue:self.visit.sessionCode forKey:@"sessionCode"];
	[_endRequest setPostValue:self.hitCode forKey:@"hitCode"];
	
	__unsafe_unretained EDHit *selfHit = self;
	
	[_endRequest setCompletionBlock:^(void){
		if (self.visit.logging) {
			NSLog(@"8digits: Hit %@ (%@) did end", self.path, self.hitCode);
		}
		[self.visit hitDidEnd:selfHit];
	}];
	
	[_endRequest setFailedBlock:^(void) {
		if (self.visit.logging) {
			NSLog(@"8digits: Hit %@ (%@) did fail to end: %@", self.path, self.hitCode, self.endRequest.error.localizedDescription);
		}
	}];
	
	[self.visit addRequest:self.endRequest];
	
}

#pragma mark - Event

- (void)eventWillTrigger:(EDEvent *)event {
	
	if ([self.eventArray containsObject:event]) {
		return;
	}
	
	[self.eventArray addObject:event];
	
}

- (void)eventDidTrigger:(EDEvent *)event {
	[self.eventArray removeObject:event];
	
	if (self.eventArray.count == 0 && self.endDate) {
		[self requestEnd];
		[self.visit hitWillEnd:self];
	}
}

#pragma mark - Encoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	self = [super init];
	
	if (self) {
		
		self.hitCode = [aDecoder decodeObjectForKey:@"hitCode"];
		
		self.title = [aDecoder decodeObjectForKey:@"title"];
		self.path = [aDecoder decodeObjectForKey:@"path"];
		
		self.registered = [aDecoder decodeBoolForKey:@"registered"];
		
		self.eventArray = [aDecoder decodeObjectForKey:@"eventArray"];
		
		self.startDate = [aDecoder decodeObjectForKey:@"startDate"];
		self.endDate = [aDecoder decodeObjectForKey:@"endDate"];
		
		self.currentlyValid = NO;
		
	}
	
	return self;
	
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	
	[aCoder encodeObject:self.hitCode forKey:@"hitCode"];
	
	[aCoder encodeObject:self.title forKey:@"title"];
	[aCoder encodeObject:self.path forKey:@"path"];
	
	[aCoder encodeBool:self.registered forKey:@"registered"];
	
	[aCoder encodeObject:self.eventArray forKey:@"eventArray"];
	
	[aCoder encodeObject:self.startDate forKey:@"startDate"];
	[aCoder encodeObject:self.endDate forKey:@"endDate"];
	
}

@end

#pragma mark -

@implementation UIViewController (EDHitAdditions)

- (void)setHit:(EDHit *)hit {
	objc_setAssociatedObject(self, @"ED_hit", hit, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (EDHit *)hit {

	EDHit *hit = objc_getAssociatedObject(self, @"ED_hit");
	
	if (hit == nil || hit.endDate) {

		hit = ED_ARC_AUTORELEASE([[EDHit alloc] initWithController:self]);
		
		EDClassInfo *info = [[EDMonitor defaultMonitor] classInfoForClass:[self class]];
		if (info) {
			[hit setTitle:info.title path:info.path];
		}
		
		[self setHit:hit];
	}
	
	return hit;
}

- (NSString *)hitCode {
	return self.hit.hitCode;
}

@end
