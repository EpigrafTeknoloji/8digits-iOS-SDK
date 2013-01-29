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

#import "ED_ARC.h"

@interface EDVisit ()

@property (nonatomic, readwrite)					BOOL				 logging;

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

@synthesize logging					= _logging;

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

#if !__has_feature(objc_arc)
- (void)dealloc {
	
	[_urlPrefix release];
	[_trackingCode release];
	
	[_authToken release];
	[_visitorCode release];
	[_sessionCode release];
	
	[_username release];
	[_password release];
	
	[_hitArray release];
	[_nonRegisteredHitArray release];
	[_eventArray release];
	
	[_startDate release];
	[_endDate release];
	
	[_authRequest release];
	[_visitRequest release];
	
	[_networkQueue release];
	
	[_reachability release];
	
	[super dealloc];
	
}
#endif

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
		
		_urlPrefix = ED_ARC_RETAIN([dict objectForKey:@"EDURLPrefix"]);
		
		if (![_urlPrefix hasPrefix:@"http://"] && ![_urlPrefix hasPrefix:@"https://"]) {
			NSString *newURLPrefix = [NSString stringWithFormat:@"http://%@", _urlPrefix];
			_urlPrefix = ED_ARC_RETAIN(newURLPrefix);
		}
		
		if ([_urlPrefix hasSuffix:@"/"]) {
			NSString *newURLPrefix = [self.urlPrefix substringToIndex:_urlPrefix.length - 1];
			_urlPrefix = ED_ARC_RETAIN(newURLPrefix);
		}
		
		_trackingCode = ED_ARC_RETAIN([dict objectForKey:@"EDTrackingCode"]);
		ED_ARC_RELEASE(dict);
		
		_authorised = NO;
		_currentlyValid = YES;
		
		_networkQueue = [[ASINetworkQueue alloc] init];
		[_networkQueue setDelegate:self];
		[_networkQueue setMaxConcurrentOperationCount:3];
		[_networkQueue setShouldCancelAllRequestsOnFailure:NO];
		[_networkQueue setQueueDidFinishSelector:@selector(queueDidFinish:)];
		
		_hitArray = [[NSMutableArray alloc] init];
		_nonRegisteredHitArray = [[NSMutableArray alloc] init];
		_eventArray = [[NSMutableArray alloc] init];
		
		_reachability = [Reachability reachabilityForInternetConnection];
		[_reachability startNotifier];
		
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
			
			CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);

			CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
#if __has_feature(objc_arc)
			_visitorCode = (__bridge_transfer NSString *)uuidString;
#else
			_visitorCode = (NSString *)uuidString;
#endif
			_visitorCode = [_visitorCode substringToIndex:8];
			
            if (self.logging) {
                NSLog(@"8digits: Created visitor code: %@", _visitorCode);
            }
			
			[[NSUserDefaults standardUserDefaults] setObject:_visitorCode forKey:@"EDVisitorCode"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			CFRelease(uuid);
			
		}
		
	}
	
	return _visitorCode;
	
}

#pragma mark - Hit add remove

- (void)addRequest:(ASIHTTPRequest *)request {
	
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
	EDEvent *event = ED_ARC_AUTORELEASE([[EDEvent alloc] initWithValue:value forKey:key]);
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
	
	self.username = username;
    self.password = password;
    self.trackingCode = trackingCode;
    
    if (![urlPrefix hasPrefix:@"http://"] && ![_urlPrefix hasPrefix:@"https://"]) {
        NSString *newURLPrefix = [NSString stringWithFormat:@"http://%@", urlPrefix];
        urlPrefix = ED_ARC_RETAIN(newURLPrefix);
    }
    
    if ([urlPrefix hasSuffix:@"/"]) {
        NSString *newURLPrefix = [urlPrefix substringToIndex:urlPrefix.length - 1];
        urlPrefix = ED_ARC_RETAIN(newURLPrefix);
    }

    self.urlPrefix = urlPrefix;
	
	[self start];
	
}


- (void)end {
//#warning Implementation
	
	self.endDate = [NSDate date];
	[self requestEnd];
	
	if (self.logging) {
		NSLog(@"8digits: Ending visit for %@", self.visitorCode);
	}
	
}

- (void)authorise {
	
	if (!self.currentlyValid || self.authorising) {
		return;
	}

	if (self.logging) {
		NSLog(@"8digits: Starting visit for %@", self.visitorCode);
	}
	
	NSString *URLString = [NSString stringWithFormat:@"%@/auth", self.urlPrefix]; 
	_authRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[_authRequest setPostValue:self.username forKey:@"username"];
	[_authRequest setPostValue:self.password forKey:@"password"];
	
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

- (void)startWithAuthToken:(NSString *)authToken {
	
	self.startDate = [NSDate date];
	
	self.authorising = NO;
	self.authorised = YES;
	self.authToken = authToken;
	
	[self requestStart];
	
}

- (void)requestStart {
	
	NSString *URLString = [NSString stringWithFormat:@"%@/visit/create", self.urlPrefix];
	_visitRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[_visitRequest setPostValue:self.authToken forKey:@"authToken"];
	[_visitRequest setPostValue:self.visitorCode forKey:@"visitorCode"];
	[_visitRequest setPostValue:self.trackingCode forKey:@"trackingCode"];
	[_visitRequest setPostValue:@"Apple" forKey:@"vendor"];
	[_visitRequest setPostValue:[[UIDevice currentDevice] model] forKey:@"brand"];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    NSString *screenWidth = [NSString stringWithFormat:@"%.0f", screenRect.size.width];
    NSString *screenHeight = [NSString stringWithFormat:@"%.0f", screenRect.size.height];
    NSString *acceptedLang = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *systemVersion = [device systemVersion];
    NSString *systemName = [device systemName];
    NSString *model = [device model];
    
    NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; U; CPU %@ %@ like Mac OS X; en-us) AppleWebKit (KHTML, like Gecko) Mobile/8A293 Safari", model, systemName, systemVersion];
    
    [_visitRequest setPostValue:userAgent forKey:@"userAgent"];
    [_visitRequest setPostValue:screenWidth forKey:@"screenWidth"];
    [_visitRequest setPostValue:screenHeight forKey:@"screenHeight"];
    [_visitRequest setPostValue:@"24" forKey:@"color"];
    [_visitRequest setPostValue:acceptedLang forKey:@"acceptLang"];
    [_visitRequest setPostValue:@"0.0.0" forKey:@"flashVersion"];
    [_visitRequest setPostValue:@"false" forKey:@"javaEnabled"];
	
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

	_visitRequest = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[_visitRequest setPostValue:self.authToken forKey:@"authToken"];
	[_visitRequest setPostValue:self.trackingCode forKey:@"trackingCode"];
	[_visitRequest setPostValue:self.sessionCode forKey:@"sessionCode"];
	[_visitRequest setPostValue:self.visitorCode forKey:@"visitorCode"];
	
	[_visitRequest startAsynchronous];
	
}

- (void)failWithError:(NSString *)error {
	[self setAuthorised:NO];
//	[self performSelector:@selector(authorise) withObject:nil afterDelay:5];
    
    if (self.logging) {
        NSLog(@"8digits: Authorization failed (%@)", error);
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EDVisitDidChangeAuthorisationStatusNotification object:self];
}

- (void)succeed {
	[self setAuthorised:YES];
	[self.networkQueue go];
	
	[self.hitArray makeObjectsPerformSelector:@selector(end)];
	[self.eventArray makeObjectsPerformSelector:@selector(trigger)];	
//	[self.nonRegisteredHitArray makeObjectsPerformSelector:@selector(start)];
	
	for (int i=0; i<self.nonRegisteredHitArray.count; i++) {
		EDHit *hit = [self.nonRegisteredHitArray objectAtIndex:i];
		[hit start];
	}
	
	EDVisitor *currentVisitor = [[EDVisitor alloc] init];
	[currentVisitor setVisitorCode:self.visitorCode];
	[currentVisitor setVisit:self];
	[EDVisitor setCurrentVisitor:currentVisitor];
	ED_ARC_RELEASE(currentVisitor);
	
	if (self.logging) {
		NSLog(@"8digits: Visitor (%@) authorised", self.visitorCode);
	}
	
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

#pragma mark - Logging

- (void)startLogging {
	NSLog(@"8digits: Started logging");
	self.logging = YES;
}

- (void)stopLogging {
	NSLog(@"8digits: Stopped logging");
	self.logging = NO;
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
