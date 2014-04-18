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


#import "ED_ARC.h"

#import "EDNetwork.h"

@interface EDVisit ()

@property (nonatomic, readwrite)					BOOL				 logging;
@property (nonatomic, assign)                       BOOL                 authorisationTried;

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



- (void)authorise;
- (void)requestStart;
- (void)requestEnd;

- (void)failWithError:(NSString *)error;
- (void)succeed;


@end

static EDVisit	*_currentVisit = nil;

@implementation EDVisit

@synthesize logging					= _logging;

@synthesize urlPrefix				= _urlPrefix;
@synthesize trackingCode			= _trackingCode;

@synthesize authToken				= _authToken;
@synthesize visitorCode				= _visitorCode;
@synthesize sessionCode				= _sessionCode;

@synthesize apiKey                  = _apiKey;

@synthesize currentlyValid			= _currentlyValid;
@synthesize authorised				= _authorised;
@synthesize authorising				= _authorising;

@synthesize hitArray				= _hitArray;
@synthesize nonRegisteredHitArray	= _nonRegisteredHitArray;
@synthesize eventArray				= _eventArray;

@synthesize startDate				= _startDate;
@synthesize endDate					= _endDate;

@synthesize validationDelegate		= _validationDelegate;

@synthesize suspended				= _suspended;

@synthesize longitude               = _longitude;
@synthesize latitude                = _latitude;

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
        
        _urlPrefix = [self configureURLPrefix:_urlPrefix];
        
        [EDNetwork sharedInstance].baseURL = _urlPrefix;
		
		_trackingCode = ED_ARC_RETAIN([dict objectForKey:@"EDTrackingCode"]);
		ED_ARC_RELEASE(dict);
		
		_authorised = NO;
        _authorisationTried = NO;
		_currentlyValid = YES;
        
        [[EDNetwork sharedInstance].queue setDelegate:self];
        [[EDNetwork sharedInstance].queue setMaxConcurrentOperationCount:3];
        
		_hitArray = [[NSMutableArray alloc] init];
		_nonRegisteredHitArray = [[NSMutableArray alloc] init];
		_eventArray = [[NSMutableArray alloc] init];
        
        
        [[EDNetwork sharedInstance] monitorReachability:^(BOOL reachable) {
            self.suspended = !reachable;
			
			if (!self.suspended) {
				
				if (!self.authorised && self.authorisationTried) {
					[self authorise];
				}
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
			
            
            [self logMessage:@"Created visitor code: %@", _visitorCode];
            
			[[NSUserDefaults standardUserDefaults] setObject:_visitorCode forKey:@"EDVisitorCode"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			CFRelease(uuid);
			
		}
		
	}
	
	return _visitorCode;
	
}

#pragma mark - Hit add remove

- (void)addRequest:(AFHTTPRequestOperation *)request {
    
	if (self.authorised && !self.suspended) {
		[[EDNetwork sharedInstance].queue addOperation:request];
		[[EDNetwork sharedInstance].queue go];
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
	
	if (!self.urlPrefix || !self.trackingCode || !self.apiKey) {
		[self.validationDelegate visitDidFailPermanently:self];
		return;
	}
	
}

- (void)start {
	
	if (!self.apiKey || !self.apiKey.length) {
		NSLog(@"8digits warning: Username or password not set, failing to start visit.");
		return;
	}
	
	[self setAuthorised:NO];
	[self setStartDate:[NSDate date]];
	[self authorise];
	
}

- (void)startWithApiKey:(NSString *)apiKey {
	[self setApiKey:apiKey];
	[self start];
}

- (void) startWithApiKey:(NSString *)apiKey trackingCode:(NSString *)trackingCode urlPrefix:(NSString *)urlPrefix {
	
	self.apiKey = apiKey;
    self.trackingCode = trackingCode;
    
    self.urlPrefix = [self configureURLPrefix:urlPrefix];
    [EDNetwork sharedInstance].baseURL = self.urlPrefix;
	
	[self start];
	
}


- (void)end {
//#warning Implementation
	
	self.endDate = [NSDate date];
	[self requestEnd];
    
    [self logMessage:@"Ending visit for %@", self.visitorCode];
	
	
}

- (void)authorise {
	
	if (!self.currentlyValid || self.authorising) {
		return;
	}
    
    [self logMessage:@"Starting visit for %@", self.visitorCode];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.apiKey, @"apiKey", nil];
    
    __unsafe_unretained EDVisit *weakSelf = self;

    
    [[EDNetwork sharedInstance] postRequest:@"auth" params:params completionBlock:^(id responseObject){
        weakSelf.authorising = NO;
		
		NSDictionary *dict = responseObject;
		weakSelf.authToken = [[dict objectForKey:@"data"] objectForKey:@"authToken"];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		weakSelf.authorised = YES;
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			[weakSelf failWithError:error];
		}
		
		else {
			[weakSelf requestStart];
		}

    } failBlock:^(NSError *error){
        weakSelf.authorising = NO;
		[weakSelf failWithError:error.localizedDescription];

    }];
	
	self.authorising = YES;
    self.authorisationTried = YES;
	
}

- (void)startWithAuthToken:(NSString *)authToken {
	
	self.startDate = [NSDate date];
	
	self.authorising = NO;
	self.authorised = YES;
	self.authToken = authToken;
	
	[self requestStart];
	
}

- (void)requestStart {
	   
    NSString *service = @"visit/create";
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    NSString *screenWidth = [NSString stringWithFormat:@"%.0f", screenRect.size.width];
    NSString *screenHeight = [NSString stringWithFormat:@"%.0f", screenRect.size.height];
    NSString *acceptedLang = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *systemVersion = [device systemVersion];
    NSString *systemName = [device systemName];
    NSString *model = [device model];
    
    NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; U; CPU %@ %@ like Mac OS X; en-us) AppleWebKit (KHTML, like Gecko) Mobile/8A293 Safari", model, systemName, systemVersion];
    

    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.authToken, @"authToken",
                            self.visitorCode, @"visitorCode",
                            self.trackingCode, @"trackingCode",
                            @"Apple", @"vendor",
                            [[UIDevice currentDevice] model], @"brand",
                            userAgent, @"userAgent",
                            screenWidth, @"screenWidth",
                            screenHeight, @"screenHeight",
                            @"24", @"color",
                            acceptedLang, @"acceptLang",
                            @"0.0.0", @"flashVersion",
                            @"false", @"javaEnabled",
                            nil];
    NSString *path = @"/";
    EDHit *hit = self.nonRegisteredHitArray[0];
    if(hit)
        path = hit.path;
    
    [params setObject:path forKey:@"path"];
    
    
    if(self.latitude != nil && self.longitude != nil) {
        [params setObject:self.latitude forKey:@"latitude"];
        [params setObject:self.longitude forKey:@"longitude"];
    }
    
    __unsafe_unretained EDVisit *selfVisit = self;

    [[EDNetwork sharedInstance] postRequest:service params:params completionBlock:^(id responseObject){
        
        NSDictionary *dict = responseObject;
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			[selfVisit failWithError:error];
		}
		
		else {
			selfVisit.sessionCode = [[dict objectForKey:@"data"] objectForKey:@"sessionCode"];
			[selfVisit succeed];
		}
        
    } failBlock:^(NSError *error){
		[selfVisit failWithError:error.localizedDescription];

    }];
    
}

- (void)requestEnd {
	   
    NSString *service = @"visit/end";
    
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.authToken, @"authToken",
                                   self.trackingCode, @"trackingCode",
                                   self.sessionCode, @"sessionCode",
                                   self.visitorCode, @"visitorCode",
                                   nil];
    
    [[EDNetwork sharedInstance] postRequest:service params:params completionBlock:nil failBlock:nil];
	
}

- (void)failWithError:(NSString *)error {
	[self setAuthorised:NO];
//	[self performSelector:@selector(authorise) withObject:nil afterDelay:5];
    
    [self logMessage:@"Authorization failed (%@)", error];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EDVisitDidChangeAuthorisationStatusNotification object:self];
}

- (void)succeed {
	[self setAuthorised:YES];
	[[EDNetwork sharedInstance].queue go];
	
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
	
    
    [self logMessage:@"Visitor (%@) authorised", self.visitorCode];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EDVisitDidChangeAuthorisationStatusNotification object:self];
}

- (void)queueDidFinish {
	
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

- (void)logMessage:(NSString *)format, ... {
    
    if(self.logging) {
        va_list args;
        va_start(args, format);
        NSLogv([NSString stringWithFormat:@"8digits: %@", format], args);
        va_end(args);
    }
}


- (void) logError:(NSString *)error {
    if(self.logging) {
        NSLog(@"8digits Error:%@", error);
    }
}

- (void)logWarning:(NSString *)warning {
    if(self.logging) {
        NSLog(@"8digits Warning:%@", warning);
    }
}


- (void)startLogging {
    self.logging = YES;
    [self logMessage:@"Started logging"];
    
}

- (void)stopLogging {
	[self logMessage:@"Stopped logging"];
	self.logging = NO;
}


#pragma mark - URLPrefix Congifguration 

- (NSString *)configureURLPrefix:(NSString *)rawPrefix {
    
    NSString *prefix = rawPrefix;
    
    if (![prefix hasPrefix:@"http://"] && ![prefix hasPrefix:@"https://"]) {
        NSString *newURLPrefix = [NSString stringWithFormat:@"http://%@", prefix];
        prefix = ED_ARC_RETAIN(newURLPrefix);
    }
    
    if ([prefix hasSuffix:@"/"]) {
        NSString *newURLPrefix = [prefix substringToIndex:prefix.length - 1];
        prefix = ED_ARC_RETAIN(newURLPrefix);
    }
    
    return prefix;
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

- (void) setLocationWithLongitude:(NSString *)longitude andLatitude:(NSString *)latitude {
    self.longitude = longitude;
    self.latitude = latitude;
}

@end
