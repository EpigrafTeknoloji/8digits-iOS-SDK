//
//  EDNetwork.m
//  EightDigits
//
//  Created by Seyithan Teymur on 23/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDVisit.h"
#import "EDVisit_Internal.h"

#import "EDHit.h"
#import "EDHit_Internal.h"
#import "EDVisitor.h"
#import "EDVisitor_Internal.h"
#import "EDEvent.h"
#import "EDMonitor.h"

#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "JSONKit.h"
#import "Reachability.h"

@interface EDVisit ()

@property (nonatomic, strong, readwrite)			NSString			*authToken;
@property (nonatomic, strong, readwrite)			NSString			*visitorCode;
@property (nonatomic, strong, readwrite)			NSString			*sessionCode;

@property (nonatomic, readwrite)					BOOL				 authorised;
@property (nonatomic, getter = isAuthorising)		BOOL				 authorising;
@property (nonatomic, getter = isCurrentlyValid)	BOOL				 currentlyValid;
@property (nonatomic, getter = isSuspended)			BOOL				 suspended;

@property (nonatomic, strong)						NSMutableArray		*hitArray;
@property (nonatomic, strong)						NSMutableArray		*nonRegisteredHitArray;
@property (nonatomic, strong)						NSMutableArray		*eventArray;

@property (nonatomic, strong)						NSDate				*startDate;
@property (nonatomic, strong)						NSDate				*endDate;

@property (nonatomic, strong)						ASIFormDataRequest	*authRequest;
@property (nonatomic, strong)						ASIFormDataRequest	*visitRequest;

@property (nonatomic, strong)						Reachability		*reachability;

- (void)authorise;
- (void)requestStart;
- (void)requestEnd;

- (void)failWithError:(NSString *)error;
- (void)succeed;

- (void)queueDidFinish:(ASINetworkQueue *)queue;

@end

static EDVisit	*_currentVisit = nil;

@implementation EDVisit

@synthesize urlPrefix				= _urlPrefix;
@synthesize trackingCode			= _trackingCode;

@synthesize authToken				= _authToken;
@synthesize visitorCode				= _visitorCode;
@synthesize sessionCode				= _sessionCode;

@synthesize username				= _username;
@synthesize password				= _password;

@synthesize currentlyValid			= _currentlyValid;
@synthesize authorised				= _authorised;
@synthesize authorising				= _authorising;

@synthesize hitArray				= _hitArray;
@synthesize nonRegisteredHitArray	= _nonRegisteredHitArray;
@synthesize eventArray				= _eventArray;

@synthesize startDate				= _startDate;
@synthesize endDate					= _endDate;

@synthesize authRequest				= _authRequest;
@synthesize visitRequest			= _visitRequest;

@synthesize networkQueue			= _networkQueue;
@synthesize validationDelegate		= _validationDelegate;

@synthesize reachability			= _reachability;
@synthesize suspended				= _suspended;

+ (EDVisit *)currentVisit {

	if (_currentVisit == nil) {
		_currentVisit = [[EDVisit alloc] init];
		[EDMonitor defaultMonitor];
	}
	
	return _currentVisit;
	
}

#pragma mark - Initializer

- (id)init {
	
	self = [super init];
	
	if (self) {
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"EightDigits" ofType:@"plist"];
		
		if (!path || !path.length) {
			NSLog(@"8digits warning: EightDigits.plist not found in bundle");
		}
		
		NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
		
		self.urlPrefix = [dict objectForKey:@"EDURLPrefix"];
		
		if ([self.urlPrefix hasSuffix:@"/"]) {
			self.urlPrefix = [self.urlPrefix substringToIndex:self.urlPrefix.length - 1];
		}
		
		self.trackingCode = [dict objectForKey:@"EDTrackingCode"];
		
		self.authorised = NO;
		self.currentlyValid = YES;
		
		self.networkQueue = [[ASINetworkQueue alloc] init];
		[self.networkQueue setDelegate:self];
		[self.networkQueue setMaxConcurrentOperationCount:3];
		[self.networkQueue setShouldCancelAllRequestsOnFailure:NO];
		[self.networkQueue setQueueDidFinishSelector:@selector(queueDidFinish:)];
		
		self.hitArray = [[NSMutableArray alloc] init];
		self.nonRegisteredHitArray = [[NSMutableArray alloc] init];
		self.eventArray = [[NSMutableArray alloc] init];
		
		self.reachability = [Reachability reachabilityForInternetConnection];
		[self.reachability startNotifier];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:self.reachability queue:nil usingBlock:^(NSNotification *notification) {
			
			self.suspended = ![self.reachability isReachable];
			
			if (!self.suspended) {
				
				if (!self.authorised) {
					[self authorise];
					return;
				}
				
				[self.networkQueue go];
				
				[self.hitArray makeObjectsPerformSelector:@selector(end)];
				[self.eventArray makeObjectsPerformSelector:@selector(trigger)];
				[self.nonRegisteredHitArray makeObjectsPerformSelector:@selector(start)];
				
			}
			
		}];
		
	}
	
	return self;
	
}

#pragma mark - Custom accessor

- (NSArray *)hits {
	return (NSArray *)self.hitArray;
}

- (NSArray *)nonRegisteredHits {
	return (NSArray *)self.nonRegisteredHitArray;
}

- (void)setUsername:(NSString *)username password:(NSString *)password {
	[self setUsername:username];
	[self setPassword:password];
}

- (NSString *)visitorCode {
	
	if (!_visitorCode) {
		
		_visitorCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"EDVisitorCode"];

		if (!_visitorCode) {
			
			CFStringRef uuid = CFUUIDCreateString(kCFAllocatorDefault, CFUUIDCreate(kCFAllocatorDefault));
			_visitorCode = (__bridge_transfer NSString *)uuid;
			_visitorCode = [_visitorCode substringToIndex:8];
			
			NSLog(@"8digits: Created visitor code: %@", _visitorCode);
			
			[[NSUserDefaults standardUserDefaults] setObject:_visitorCode forKey:@"EDVisitorCode"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
		}
		
	}
	
	return _visitorCode;
	
}

#pragma mark - Hit add remove

- (void)addRequest:(ASIHTTPRequest *)request {
	
//	NSLog(@"Adding request: %@", request.url.absoluteString);
	
	if (self.authorised && !self.suspended) {
		[self.networkQueue addOperation:request];
		[self.networkQueue go];
	}
	
}

- (void)hitWillStart:(EDHit *)hit {
	
	[self.hitArray removeObject:hit];
	[self.nonRegisteredHitArray removeObject:hit];
	
	[self.nonRegisteredHitArray addObject:hit];
	
}

- (void)hitDidStart:(EDHit *)hit {
	
	[self.hitArray removeObject:hit];
	[self.nonRegisteredHitArray removeObject:hit];
	
	[self.hitArray addObject:hit];
	
	if (hit.endDate) {
		[hit end];
	}
	
}

- (void)hitWillEnd:(EDHit *)hit {
	
}

- (void)hitDidEnd:(EDHit *)hit {
	
	[self.hitArray removeObject:hit];
	[self.nonRegisteredHitArray removeObject:hit];
	
}

#pragma mark - Event

- (void)triggerEventWithValue:(NSString *)value forKey:(NSString *)key {
	EDEvent *event = [[EDEvent alloc] initWithValue:value forKey:key];
	[event trigger];
}

- (void)eventWillTrigger:(EDEvent *)event {

	if ([self.eventArray containsObject:event]) {
		return;
	}
	
	[self.eventArray addObject:event];
	
}

- (void)eventDidTrigger:(EDEvent *)event {
	[self.eventArray removeObject:event];
}

#pragma mark - Start stop

- (void)validate {
	
	if (!self.urlPrefix || !self.trackingCode || !self.username || !self.password) {
		[self.validationDelegate visitDidFailPermanently:self];
		return;
	}
	
}

- (void)start {
	
	if (!self.password || !self.password.length || !self.username || !self.username.length) {
		NSLog(@"8digits warning: Username or password not set, failing to start visit.");
		return;
	}
	
	[self setAuthorised:NO];
	[self setStartDate:[NSDate date]];
	[self authorise];
	
}

- (void)startWithUsername:(NSString *)username password:(NSString *)password {
	[self setUsername:username password:password];
	[self start];
}

- (void)startWithUsername:(NSString *)username password:(NSString *)password trackingCode:(NSString *)trackingCode urlPrefix:(NSString *)urlPrefix {
	
	if (!username || !username.length) {
		self.username = username;
	}
	
	if (!trackingCode || !trackingCode.length) {
		self.trackingCode = trackingCode;
	}
	
	if (!urlPrefix || !urlPrefix.length) {
		self.urlPrefix = urlPrefix;
	}
	
	[self start];
	
}


- (void)end {
	
	self.endDate = [NSDate date];
	[self requestEnd];
	
}

- (void)authorise {
	
	if (!self.currentlyValid || self.authorising) {
		return;
	}

	NSString *URLString = [NSString stringWithFormat:@"%@/auth", self.urlPrefix]; 
	self.authRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.authRequest setPostValue:self.username forKey:@"username"];
	[self.authRequest setPostValue:self.password forKey:@"password"];
	
	__unsafe_unretained EDVisit *selfVisit = self;
	
	[self.authRequest setCompletionBlock:^(void){
		self.authorising = NO;
		
		NSDictionary *dict = [self.authRequest.responseString objectFromJSONString];
		self.authToken = [[dict objectForKey:@"data"] objectForKey:@"authToken"];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];		
		self.authorised = YES;
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			[selfVisit failWithError:error];
		}
		
		else {
			[selfVisit requestStart];
		}
		
	}];
	
	[self.authRequest setFailedBlock:^(void){
		self.authorising = NO;
		NSString *error = [[self.visitRequest error] localizedDescription];
		[selfVisit failWithError:error];
	}];

	self.authorising = YES;
	[self.authRequest startAsynchronous];
	
}

- (void)requestStart {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/visit/create", self.urlPrefix];
	self.visitRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.visitRequest setPostValue:self.authToken forKey:@"authToken"];
	[self.visitRequest setPostValue:self.visitorCode forKey:@"visitorCode"];
	[self.visitRequest setPostValue:self.trackingCode forKey:@"trackingCode"];
	
	__unsafe_unretained EDVisit *selfVisit = self;
	
	[self.visitRequest setCompletionBlock:^(void){
		NSDictionary *dict = [self.visitRequest.responseString objectFromJSONString];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];		
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			[selfVisit failWithError:error];
		}
		
		else {
			self.sessionCode = [[dict objectForKey:@"data"] objectForKey:@"sessionCode"];
			[selfVisit succeed];
		}
		
	}];
	
	[self.visitRequest setFailedBlock:^(void){
		NSString *error = [[self.visitRequest error] localizedDescription];
		[selfVisit failWithError:error];
	}];
	
	[self.visitRequest startAsynchronous];
	
}

- (void)requestEnd {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/visit/end", self.urlPrefix];
	self.visitRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[self.visitRequest setValue:self.authToken forKey:@"authToken"];
	[self.visitRequest setValue:self.trackingCode forKey:@"trackingCode"];
	[self.visitRequest setValue:self.sessionCode forKey:@"sessionCode"];
	[self.visitRequest setValue:self.visitorCode forKey:@"visitorCode"];
	
	[self.visitRequest startAsynchronous];
	
}

- (void)failWithError:(NSString *)error {
	[self setAuthorised:NO];
//	[self performSelector:@selector(authorise) withObject:nil afterDelay:5];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EDVisitDidChangeAuthorisationStatusNotification object:self];
}

- (void)succeed {
	[self setAuthorised:YES];
	[self.networkQueue go];
	
	[self.hitArray makeObjectsPerformSelector:@selector(end)];
	[self.eventArray makeObjectsPerformSelector:@selector(trigger)];	
	[self.nonRegisteredHitArray makeObjectsPerformSelector:@selector(start)];
	
	EDVisitor *currentVisitor = [[EDVisitor alloc] init];
	[currentVisitor setVisitorCode:self.visitorCode];
	[currentVisitor setVisit:self];
	[EDVisitor setCurrentVisitor:currentVisitor];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EDVisitDidChangeAuthorisationStatusNotification object:self];
}

- (void)queueDidFinish:(ASINetworkQueue *)queue {
	
	if (self.currentlyValid) {
		return;
	}
	
	BOOL allDone = NO;
	
	for (EDHit *hit in self.hits) {
		allDone = hit.registered;
		
		if (!allDone) {
			break;
		}
		
	}
	
	if (allDone) {
		self.authorised = YES;
		[self.validationDelegate visit:self didGetValidatedSuccessfully:YES];
	}
	
}

#pragma mark - Encoding

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	self = [super init];
	
	if (self) {
		self.urlPrefix = [aDecoder decodeObjectForKey:@"urlPrefix"];
		self.trackingCode = [aDecoder decodeObjectForKey:@"trackingCode"];
		self.sessionCode = [aDecoder decodeObjectForKey:@"sessionCode"];
		
		self.authorised = [aDecoder decodeBoolForKey:@"authorised"];
		
		self.hitArray = [aDecoder decodeObjectForKey:@"hitArray"];
		self.nonRegisteredHitArray = [aDecoder decodeObjectForKey:@"nonRegisteredHitArray"];
		
		self.startDate = [aDecoder decodeObjectForKey:@"startDate"];
		self.endDate = [aDecoder decodeObjectForKey:@"endDate"];
		
		self.currentlyValid = NO;		
	}
	
	return self;
	
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	
	[aCoder encodeObject:self.urlPrefix forKey:@"urlPrefix"];
	[aCoder encodeObject:self.trackingCode forKey:@"trackingCode"];
	[aCoder encodeObject:self.sessionCode forKey:@"sessionCode"];
	
	[aCoder encodeBool:self.authorised forKey:@"authorised"];
	
	[aCoder encodeObject:self.hitArray forKey:@"hitArray"];
	[aCoder encodeObject:self.nonRegisteredHitArray forKey:@"nonRegisteredHitArray"];
	
	[aCoder encodeObject:self.startDate forKey:@"startDate"];
	[aCoder encodeObject:self.endDate forKey:@"endDate"];
	
}

@end
