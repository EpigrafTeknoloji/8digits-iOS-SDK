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
		self.eventArray = [[NSMutableArray alloc] init];
	}
	
	return self;
	
}

#pragma mark - Custom accessor

- (NSString *)hitCode {
	
	if (_hitCode == nil) {
		NSInteger hitCode = arc4random() % NSIntegerMax;
		_hitCode = [NSString stringWithFormat:@"%i", hitCode];
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
	
	[self setRegistered:NO];
	[self setStartDate:[NSDate date]];
	[self requestStart];
	
	[self.visit hitWillStart:self];
	
}

- (void)end {
	
	[self setEndDate:[NSDate date]];
	
	if (!self.registered || self.events.count) {
		return;
	}
	
	[self requestEnd];
	[self.visit hitWillEnd:self];
	
}

- (void)requestStart {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/hit/create", self.visit.urlPrefix];
	self.startRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.startRequest setPostValue:self.visit.authToken forKey:@"authToken"];
	[self.startRequest setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[self.startRequest setPostValue:self.visit.visitorCode forKey:@"visitorCode"];
	[self.startRequest setPostValue:self.visit.sessionCode forKey:@"sessionCode"];
	[self.startRequest setPostValue:self.title forKey:@"pageTitle"];
	[self.startRequest setPostValue:self.path forKey:@"path"];
	[self.startRequest setPostValue:self.hitCode forKey:@"hitCode"];
	
	__unsafe_unretained EDHit *selfHit = self;
	
	[self.startRequest setCompletionBlock:^(void) {
		NSDictionary *dict = [self.startRequest.responseString objectFromJSONString];
		self.hitCode = [[dict objectForKey:@"data"] objectForKey:@"hitCode"];
		
		self.registered = YES;
		[self.visit hitDidStart:selfHit];
		
		[self.eventArray makeObjectsPerformSelector:@selector(trigger)];
		
	}];
	
	[self.startRequest setFailedBlock:^(void){
	}];
	
	[self.startRequest setQueuePriority:self.events.count > 0 ? NSOperationQueuePriorityVeryHigh : NSOperationQueuePriorityHigh];
	
	[self.visit addRequest:self.startRequest];
	
}

- (void)requestEnd {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/hit/end", self.visit.urlPrefix];
	self.endRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.endRequest setPostValue:self.visit.authToken forKey:@"authToken"];
	[self.endRequest setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[self.endRequest setPostValue:self.visit.visitorCode forKey:@"visitorCode"];
	[self.endRequest setPostValue:self.visit.sessionCode forKey:@"sessionCode"];
	[self.endRequest setPostValue:self.hitCode forKey:@"hitCode"];
	
	__unsafe_unretained EDHit *selfHit = self;
	
	[self.endRequest setCompletionBlock:^(void){
		[self.visit hitDidEnd:selfHit];
	}];
	
	[self.endRequest setFailedBlock:^(void) {
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
		hit = [[EDHit alloc] initWithController:self];
		
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
