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

@interface EDVisitor () {
    NSMutableDictionary *_visitorAttributes;
}

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

@synthesize fullName        = _fullName;
@synthesize gender          = _gender;
@synthesize age             = _age;
@synthesize avatarPath      = _avatarPath;

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

- (NSDictionary *)visitorAttributes {
    
    if (_visitorAttributes == nil) {
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"EDVisitorInfo"];
        
        _visitorAttributes = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        if (_visitorAttributes == nil) {
            _visitorAttributes = [[NSMutableDictionary alloc] init];
        }
        
    }
    
    return _visitorAttributes;
}

- (NSURL *)urlForImageForBadgeWithID:(NSString *)badgeID {
	NSString *URLString = [NSString stringWithFormat:@"%@/badge/image/%@", self.visit.urlPrefix, badgeID];
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

- (void)setVisitorAttributesFromDictionary:(NSDictionary *)dictionary withCompletionHandler:(void (^)(NSString *))completionHandler {
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"EDVisitorInfo"];
    
    if (_visitorAttributes == nil) {
        _visitorAttributes = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        if (_visitorAttributes == nil) {
            _visitorAttributes = [[NSMutableDictionary alloc] init];
        }
        
    }
    
    NSMutableString *keyString = [[NSMutableString alloc] init];
    NSMutableString *valueString = [[NSMutableString alloc] init];
    
    for (NSString *key in dictionary.allKeys) {
        NSString *value = [dictionary valueForKey:key];
        [keyString appendFormat:@"%@;; ", key];
        [valueString appendFormat:@"%@;; ", value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 3, 3)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 3, 3)];
    
    NSString *URLString = [NSString stringWithFormat:@"%@/visitor/setAttribute", self.visit.urlPrefix];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:URLString]];
	[request setPostValue:self.visit.authToken forKey:@"authToken"];
	[request setPostValue:self.visitorCode forKey:@"visitorCode"];
	[request setPostValue:self.visit.trackingCode forKey:@"trackingCode"];
	[request setPostValue:keyString forKey:@"keys"];
    [request setPostValue:valueString forKey:@"values"];
	
	[request setCompletionBlock:^(void){
        
		NSDictionary *dict = [request.responseString objectFromJSONString];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			if (completionHandler) {
				completionHandler(error);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Failed to set values for keys: %@, reason: %@", keyString, error);
			}
		}
		
		else {
			[_visitorAttributes addEntriesFromDictionary:dictionary];
            [_visitorAttributes writeToFile:path atomically:YES];

			if (completionHandler) {
				completionHandler(nil);
			}
			if (self.visit.logging) {
				NSLog(@"8digits: Successfully set values for keys: %@ for visitor: %@", keyString, self.visitorCode);
			}
		}
		
	}];
	
	[request setFailedBlock:^(void){
		NSString *error = [request.error localizedDescription];
		self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(error);
		}
		if (self.visit.logging) {
            NSLog(@"8digits: Failed to set values for keys: %@, reason: %@", keyString, error);
		}
	}];
	
	[self.queue addOperation:request];
	[self.queue go];
    
}

- (NSString *)fullName {
    if (_fullName == nil) {
        _fullName = [self.visitorAttributes objectForKey:@"fullName"];
    }
    return _fullName;
}

- (EDVisitorGender)gender {
    if (_gender == EDVisitorGenderNotSpecified) {
        NSString *genderString = [self.visitorAttributes objectForKey:@"gender"];
        if (genderString == nil) {
            _gender = EDVisitorGenderNotSpecified;
        }
        else {
            _gender = [genderString isEqualToString:@"M"] ? EDVisitorGenderMale : EDVisitorGenderFemale;
        }
    }
    return _gender;
}

- (NSInteger)age {
    if (_age == 0) {
        _age = [[self.visitorAttributes objectForKey:@"age"] integerValue];
    }
    return _age;
}

- (NSString *)avatarPath {
    if (_avatarPath == nil) {
        _avatarPath = [self.visitorAttributes objectForKey:@"avatarPath"];
    }
    return _avatarPath;
}

- (void)setFullName:(NSString *)fullName {
    if ([_fullName isEqualToString:fullName]) {
        return;
    }
    [self setVisitorAttributesFromDictionary:@{@"fullName" : fullName} withCompletionHandler:nil];
}

- (void)setGender:(EDVisitorGender)gender {
    if (_gender == gender) {
        return;
    }
    
    if (gender == EDVisitorGenderNotSpecified) {
        return;
    }
    
    NSString *genderString = gender == EDVisitorGenderMale ? @"M" : @"F";
    [self setVisitorAttributesFromDictionary:@{@"gender" : genderString} withCompletionHandler:nil];
}

- (void)setAge:(NSInteger)age {
    if (_age == age) {
        return;
    }
    [self setVisitorAttributesFromDictionary:@{@"age" : [NSString stringWithFormat:@"%i", age]} withCompletionHandler:nil];
}

- (void)setAvatarPath:(NSString *)avatarPath {
    if (_avatarPath == avatarPath) {
        return;
    }
    [self setVisitorAttributesFromDictionary:@{@"avatarPath" : avatarPath} withCompletionHandler:nil];
}

@end