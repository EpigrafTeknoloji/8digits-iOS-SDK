//
//  EDVisitor.m
//  EightDigits
//
//  Created by Seyithan Teymur on 28/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDVisitor.h"
#import "EDVisitor_Internal.h"

#import "EDVisit.h"

#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "JSONKit.h"

#import "ED_ARC.h"

@interface EDVisitor ()

@property (nonatomic, strong)				ASINetworkQueue	*queue;

@property (nonatomic, strong, readwrite)	NSArray			*badges;
@property (nonatomic, assign, readwrite)	NSInteger		 score;

@end

static EDVisitor *_currentVisitor = nil;

@implementation EDVisitor

@synthesize queue			= _queue;

@synthesize visitorCode		= _visitorCode;

@synthesize badges			= _badges;
@synthesize score			= _score;

@synthesize visit			= _visit;

#if !__has_feature(objc_arc)
- (void)dealloc {
	
	[_queue release];
	[_badges release];
	
	[super dealloc];
	
}
#endif

#pragma mark - Init

+ (EDVisitor *)currentVisitor {
	return _currentVisitor;
}

+ (void)setCurrentVisitor:(EDVisitor *)visitor {
	_currentVisitor = ED_ARC_RETAIN(visitor);
}

- (id)init {
	
	self = [super init];
	
	if (self) {
		_queue = [[ASINetworkQueue alloc] init];
		[_queue setMaxConcurrentOperationCount:1];
		[_queue setShouldCancelAllRequestsOnFailure:NO];
		
		_score = EDVisitorScoreNotLoaded;
	}
	
	return self;
	
}

#pragma mark - Public

- (NSURL *)urlForImageForBadgeWithID:(NSString *)badgeID {
	NSString *URLString = [NSString stringWithFormat:@"%@/badge/image/%@", self.visitorCode, badgeID];
	return [NSURL URLWithString:URLString];
}

- (void)loadBadgesWithCompletionHandler:(void (^)(NSArray *badges, NSString *error))completionHandler {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/visitor/badges", self.visit.urlPrefix];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[request setPostValue:self.visit.authToken forKey:@"authToken"];
	[request setPostValue:self.visitorCode forKey:@"visitorCode"];
	[request setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	
	[request setCompletionBlock:^(void){
	
		NSDictionary *dict = [request.responseString objectFromJSONString];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			self.badges = nil;
			if (completionHandler) {
				completionHandler(nil, error);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Failed to load badges for %@, reason: %@", self.visitorCode, error);
			}
		}
		
		else {
			self.badges = [[dict objectForKey:@"data"] objectForKey:@"badges"];
			if (completionHandler) {
				completionHandler(self.badges, nil);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Loaded %i badges for %@", self.badges.count, self.visitorCode);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.badges = nil;
		if (completionHandler) {
			completionHandler(nil, error);
		}
		if (self.visit.logging) {
			NSLog(@"8digits: Failed to load badges for %@, reason: %@", self.visitorCode, error);
		}
	}];
	
	[self.queue addOperation:request];
	[self.queue go];
	
}

- (void)loadScoreWithCompletionHandler:(void (^)(NSInteger score, NSString *error))completionHandler {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/visitor/score", self.visit.urlPrefix];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[request setPostValue:self.visit.authToken forKey:@"authToken"];
	[request setPostValue:self.visitorCode forKey:@"visitorCode"];
	[request setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	
	[request setCompletionBlock:^(void){
		
		NSDictionary *dict = [request.responseString objectFromJSONString];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			self.score = EDVisitorScoreNotLoaded;
			if (completionHandler) {
				completionHandler(self.score, error);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Failed to load score for %@, reason: %@", self.visitorCode, error);
			}
		}
		
		else {
			self.score = [[[dict objectForKey:@"data"] objectForKey:@"score"] integerValue];
			
			if (completionHandler) {
				completionHandler(self.score, nil);
			}
			
			if (self.visit.logging) {
				NSLog(@"8digits: Loaded score (%i) for %@", self.score, self.visitorCode);
			}
			
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(self.score, error);
		}
		if (self.visit.logging) {
			NSLog(@"8digits: Failed to load score for %@, reason: %@", self.visitorCode, error);
		}
	}];
	
	[self.queue addOperation:request];
	[self.queue go];
	
}

- (void)increaseScoreBy:(NSInteger)differential withCompletionHandler:(void (^)(NSInteger score, NSString *error))completionHandler {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/score/increase", self.visit.urlPrefix];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[request setPostValue:self.visit.authToken forKey:@"authToken"];
	[request setPostValue:self.visitorCode forKey:@"visitorCode"];
	[request setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[request setPostValue:[NSString stringWithFormat:@"%i", differential] forKey:@"value"];
	
	[request setCompletionBlock:^(void){
		
		NSDictionary *dict = [request.responseString objectFromJSONString];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			self.score = EDVisitorScoreNotLoaded;
			if (completionHandler) {
				completionHandler(self.score, error);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Failed to increase score for %@, reason: %@", self.visitorCode, error);
			}
		}
		
		else {
			self.score = [[[dict objectForKey:@"data"] objectForKey:@"score"] integerValue];
			if (completionHandler) {
				completionHandler(self.score, nil);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Increased score (%i, %i) for %@", differential, self.score, self.visitorCode);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(self.score, error);
		}
		if (self.visit.logging) {
			NSLog(@"8digits: Failed to increase score for %@, reason: %@", self.visitorCode, error);
		}
	}];
	
	[self.queue addOperation:request];
	[self.queue go];
	
}

- (void)decreaseScoreBy:(NSInteger)differential withCompletionHandler:(void (^)(NSInteger score, NSString *error))completionHandler {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/score/decrease", self.visit.urlPrefix];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[request setPostValue:self.visit.authToken forKey:@"authToken"];
	[request setPostValue:self.visitorCode forKey:@"visitorCode"];
	[request setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[request setPostValue:[NSString stringWithFormat:@"%i", differential] forKey:@"value"];
	
	[request setCompletionBlock:^(void){
	
		NSDictionary *dict = [request.responseString objectFromJSONString];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			self.score = EDVisitorScoreNotLoaded;
			if (completionHandler) {
				completionHandler(self.score, error);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Failed to decrease score for %@, reason: %@", self.visitorCode, error);
			}
		}
		
		else {
			self.score = [[[dict objectForKey:@"data"] objectForKey:@"score"] integerValue];
			if (completionHandler) {
				completionHandler(self.score, nil);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Decreased score (%i, %i) for %@", differential, self.score, self.visitorCode);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(self.score, error);
		}
		if (self.visit.logging) {
			NSLog(@"8digits: Failed to decrease score for %@, reason: %@", self.visitorCode, error);
		}
	}];
	
	[self.queue addOperation:request];
	[self.queue go];
	
}

@end