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

#pragma mark - Init

+ (EDVisitor *)currentVisitor {
	return _currentVisitor;
}

+ (void)setCurrentVisitor:(EDVisitor *)visitor {
	_currentVisitor = visitor;
}

- (id)init {
	
	self = [super init];
	
	if (self) {
		self.queue = [[ASINetworkQueue alloc] init];
		[self.queue setMaxConcurrentOperationCount:1];
		[self.queue setShouldCancelAllRequestsOnFailure:NO];
		
		self.score = EDVisitorScoreNotLoaded;
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
		}
		
		else {
			self.badges = [[dict objectForKey:@"data"] objectForKey:@"badges"];
			if (completionHandler) {
				completionHandler(self.badges, nil);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.badges = nil;
		if (completionHandler) {
			completionHandler(nil, error);
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
		}
		
		else {
			self.score = [[[dict objectForKey:@"data"] objectForKey:@"score"] integerValue];
			
			if (completionHandler) {
				completionHandler(self.score, nil);
			}
			
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(self.score, error);
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
		}
		
		else {
			self.score = [[[dict objectForKey:@"data"] objectForKey:@"score"] integerValue];
			if (completionHandler) {
				completionHandler(self.score, nil);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(self.score, error);
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
		}
		
		else {
			self.score = [[[dict objectForKey:@"data"] objectForKey:@"score"] integerValue];
			if (completionHandler) {
				completionHandler(self.score, nil);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(self.score, error);
		}
	}];
	
	[self.queue addOperation:request];
	[self.queue go];
	
}

@end