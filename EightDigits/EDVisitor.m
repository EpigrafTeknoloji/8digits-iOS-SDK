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
#import "EDVisit_Internal.h"

//#import "ASIFormDataRequest.h"
//#import "ASINetworkQueue.h"
//#import "JSONKit.h"

#import "EDNetwork.h"

#import "ED_ARC.h"

@interface EDVisitor () {
    NSMutableDictionary *_visitorAttributes;
}

//@property (nonatomic, strong)				ASINetworkQueue	*queue;

@property (nonatomic, strong, readwrite)	NSArray			*badges;
@property (nonatomic, assign, readwrite)	NSInteger		 score;

@end

static EDVisitor *_currentVisitor = nil;

@implementation EDVisitor

//@synthesize queue			= _queue;

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
//		_queue = [[ASINetworkQueue alloc] init];
//		[_queue setMaxConcurrentOperationCount:1];
//		[_queue setShouldCancelAllRequestsOnFailure:NO];
		
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

- (NSMutableDictionary *)defaultPostParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.visit.authToken, @"authToken",
                            self.visitorCode, @"visitorCode",
                            self.visit.trackingCode, @"trackingCode",
                            nil];
    return params;
}

- (void)loadBadgesWithCompletionHandler:(void (^)(NSArray *badges, NSString *error))completionHandler {
    
    NSString *service = @"visitor/badges";
    
    NSMutableDictionary *params = [self defaultPostParams];
    
    AFHTTPRequestOperation *operation = [[EDNetwork sharedInstance] baseRequest:service type:@"POST" params:params returning:YES completionBlock:^(id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:responseObject];
		
		NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
            
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			self.badges     = nil;
			if (completionHandler) {
				completionHandler(nil, error);
			}
            
            [self.visit logMessage:@"Failed to load badges for %@, reason: %@", self.visitorCode, error];

		}
		
		else {
            
			self.badges = [[dict objectForKey:@"data"] objectForKey:@"badges"];
			if (completionHandler) {
				completionHandler(self.badges, nil);
			}
            
		}
        
        ED_ARC_RELEASE(dict);

    } failBlock:^(NSError *error) {
        
		self.badges = nil;
		if (completionHandler) {
			completionHandler(nil, error.localizedDescription);
		}
		if (self.visit.logging) {
			NSLog(@"8digits: Failed to load badges for %@, reason: %@", self.visitorCode, error);
		}
    }];
                            
    [self.visit addRequest:operation];
	
    ED_ARC_RELEASE(params);
	
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
//    NSArray *keys = [NSArray arrayWithObject:keyString];
//    NSArray *values = [NSArray arrayWithObject:valueString];
    
    NSString *service = @"attr/set";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.visit.authToken, @"authToken",
                                   self.visitorCode, @"visitorCode",
                                   self.visit.trackingCode, @"trackingCode",
                                   keyString, @"name",
                                   valueString, @"value", nil];
    
    AFHTTPRequestOperation *operation = [[EDNetwork sharedInstance] baseRequest:service type:@"POST" params:params returning:YES completionBlock:^(id responseObject) {
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:responseObject];
        
        NSInteger result = [[[dict objectForKey:@"result"] objectForKey:@"code"] intValue];
		
		if (result != 0) {
			NSString *error = [[dict objectForKey:@"result"] objectForKey:@"message"];
			if (completionHandler) {
				completionHandler(error);
			}
            [self.visit logMessage:@"Failed to set values for keys: %@, reason: %@", keyString, error];
		}
		
		else {
			[_visitorAttributes addEntriesFromDictionary:dictionary];
            [_visitorAttributes writeToFile:path atomically:YES];
            
			if (completionHandler) {
				completionHandler(nil);
			}
            [self.visit logMessage:@"Successfully set values for keys: %@ for visitor: %@", keyString, self.visitorCode];
		}
        
        ED_ARC_RELEASE(dict);

    } failBlock:^(NSError *error) {
        self.score = EDVisitorScoreNotLoaded;
		if (completionHandler) {
			completionHandler(error.localizedDescription);
		}
        [self.visit logMessage:@"Failed to set values for keys: %@, reason: %@", keyString, error];
    }];
    
    [self.visit addRequest:operation];
    
    ED_ARC_RELEASE(params);
    
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