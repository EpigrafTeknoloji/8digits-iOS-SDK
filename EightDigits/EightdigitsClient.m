//
//  EightdigitsClient.m
//
//  Copyright (c) 2012 8digits.com. All rights reserved.
//

#import "EightdigitsClient.h"
#import "ASIFormDataRequest.h"
#import "SBJSON.h"
#import "UIDevice+IdentifierAddition.h"

@interface EightdigitsClient (Private)
- (NSDictionary *) getAndParse:(ASIFormDataRequest *)request;
@end

@implementation EightdigitsClient

@synthesize authToken, visitorCode, sessionCode, urlPrefix, trackingCode, username, password;

#pragma mark Initiation
- (id)initWithUrlPrefix:(NSString *)_urlPrefix trackingCode:(NSString *)_trackingCode {
    if (self = [super init]) {
        self.urlPrefix = _urlPrefix;
        self.trackingCode = _trackingCode;
        self.visitorCode = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
    }
    return self;
}

#pragma mark Authentication
- (void)authWithUsername:(NSString *)_username password:(NSString *)_password {
    self.username = _username;
    self.password = _password;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/auth", self.urlPrefix]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:_username forKey:@"username"];
    [request setPostValue:_password forKey:@"password"];
    [request startSynchronous];
    NSDictionary *result = [self getAndParse:request];
    self.authToken = [result objectForKey:@"authToken"];
}

#pragma mark Score Fetch
- (NSInteger)score {
    BOOL onceMore = YES;
    NSDecimalNumber *scoreDecimal = nil;
    
    while (onceMore == YES) {
        @try {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/visitor/score", self.urlPrefix]];
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
            [request setPostValue:self.authToken forKey:@"authToken"];
            [request setPostValue:self.trackingCode forKey:@"trackingCode"];
            [request setPostValue:self.visitorCode forKey:@"visitorCode"];
            [request startSynchronous];
            NSDictionary *result = [self getAndParse:request];
            scoreDecimal = [result objectForKey:@"score"];
            onceMore = NO;
        }
        @catch (NSException *exception) {
            sleep(1);
            onceMore = YES;
        }
    }
    return [scoreDecimal intValue];
}

#pragma mark Badges
- (NSArray *)badges {
    BOOL onceMore = YES;
    NSArray *badges = nil;
    
    while (onceMore == YES) {
        @try {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/visitor/badges", self.urlPrefix]];
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
            [request setPostValue:self.authToken forKey:@"authToken"];
            [request setPostValue:self.trackingCode forKey:@"trackingCode"];
            [request setPostValue:self.visitorCode forKey:@"visitorCode"];
            [request startSynchronous];
            NSDictionary *result = [self getAndParse:request];
            badges = [result objectForKey:@"badges"];
            onceMore = NO;
        }
        @catch (NSException *exception) {
            sleep(1);
            onceMore = YES;
        }
    }
    
    return badges;
}

-(UIImage *)badgeImageForId:(NSString *)badgeId {
    BOOL onceMore = YES;
    UIImage *image = nil;
    
    while (onceMore == YES) {
        @try {
            NSString *imgUrl = [NSString stringWithFormat:@"%@/api/badge/image/%@", self.urlPrefix, badgeId];
            NSData *data = [self getDataAsNSData:imgUrl];
            image = [UIImage imageWithData:data];
            onceMore = NO;
        }
        @catch (NSException *exception) {
            sleep(1);
            onceMore = YES;
        }
    }
    return image;
}

#pragma mark New Visit

- (NSString *)newVisitWithTitle:(NSString *)title path:(NSString *)path {
    BOOL onceMore = YES;
    NSString *tmpCode = nil;
    
    while (onceMore == YES) {
        @try {
            UIDevice *device = [UIDevice currentDevice];
            NSString *systemVersion = [device systemVersion];
            NSString *systemName = [device systemName];
            NSString *model = [device model];
            
            NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; U; CPU %@ %@ like Mac OS X; en-us) AppleWebKit (KHTML, like Gecko) Mobile/8A293 Safari", model, systemName, systemVersion];
            
            CGRect rectScreen = [[UIScreen mainScreen] bounds];
            NSString *screenWidth = [NSString stringWithFormat:@"%d", (int)rectScreen.size.width];
            NSString *screenHeight = [NSString stringWithFormat:@"%d", (int)rectScreen.size.height];
            NSString *acceptLang = [[NSLocale preferredLanguages] objectAtIndex:0];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/visit/create", self.urlPrefix]];
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
            [request setPostValue:self.authToken forKey:@"authToken"];
            [request setPostValue:self.trackingCode forKey:@"trackingCode"];
            [request setPostValue:self.visitorCode forKey:@"visitorCode"];
            [request setPostValue:title forKey:@"pageTitle"];
            [request setPostValue:path forKey:@"path"];
            [request setPostValue:userAgent forKey:@"userAgent"];
            [request setPostValue:screenWidth forKey:@"screenWidth"];
            [request setPostValue:screenHeight forKey:@"screenHeight"];
            [request setPostValue:@"24" forKey:@"color"];
            [request setPostValue:acceptLang forKey:@"acceptLang"];
            [request setPostValue:@"0.0.0" forKey:@"flashVersion"];
            [request setPostValue:@"false" forKey:@"javaEnabled"];
            
            [request startSynchronous];
            NSDictionary *result = [self getAndParse:request];
            self.sessionCode = [result objectForKey:@"sessionCode"];
            tmpCode = [result objectForKey:@"hitCode"];
            onceMore = NO;
        }
        @catch (NSException *exception) {
            sleep(1);
            onceMore = YES;
        }
    }
    return tmpCode;
}

#pragma mark End Screen
- (void)endScreenWithHitCode:(NSString *)hitCode {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/hit/end", self.urlPrefix]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:self.authToken forKey:@"authToken"];
    [request setPostValue:self.trackingCode forKey:@"trackingCode"];
    [request setPostValue:self.visitorCode forKey:@"visitorCode"];
    [request setPostValue:self.sessionCode forKey:@"sessionCode"];
    [request setPostValue:hitCode forKey:@"hitCode"];
    [request setDelegate:self];
    [request startAsynchronous];
}

#pragma mark Send Event
- (void)eventWithKey:(NSString *)key value:(NSString *)value hitCode:(NSString *)hitCode {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/event/create", self.urlPrefix]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:self.authToken forKey:@"authToken"];
    [request setPostValue:self.trackingCode forKey:@"trackingCode"];
    [request setPostValue:self.visitorCode forKey:@"visitorCode"];
    [request setPostValue:self.sessionCode forKey:@"sessionCode"];
    [request setPostValue:hitCode forKey:@"hitCode"];
    [request setPostValue:key forKey:@"key"];
    [request setPostValue:value forKey:@"value"];
    [request setDelegate:self];
    [request startAsynchronous];
}

#pragma New Screen
- (NSString *)newScreenWithTitle:(NSString *)title path:(NSString *)path {
    BOOL onceMore = YES;
    NSString *hitCode = nil;
    
    while (onceMore == YES) {
        @try {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/hit/create", self.urlPrefix]];
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
            [request setPostValue:self.authToken forKey:@"authToken"];
            [request setPostValue:self.trackingCode forKey:@"trackingCode"];
            [request setPostValue:self.visitorCode forKey:@"visitorCode"];
            [request setPostValue:self.sessionCode forKey:@"sessionCode"];
            [request setPostValue:title forKey:@"pageTitle"];
            [request setPostValue:path forKey:@"path"];
            [request startSynchronous];
            NSDictionary *result = [self getAndParse:request];
            hitCode = [result objectForKey:@"hitCode"];
            onceMore = NO;
        }
        @catch (NSException *exception) {
            sleep(1);
            onceMore = YES;
        }
    }
    return hitCode;
}

#pragma mark End Visit
- (void)endVisit {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/visit/end", self.urlPrefix]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:self.authToken forKey:@"authToken"];
    [request setPostValue:self.trackingCode forKey:@"trackingCode"];
    [request setPostValue:self.visitorCode forKey:@"visitorCode"];
    [request setPostValue:self.sessionCode forKey:@"sessionCode"];
    [request setDelegate:self];
    [request startAsynchronous];
}

#pragma mark Async request handlers
- (void)requestFinished:(ASIHTTPRequest *)request {
    NSString *response = [request responseString];
    SBJSON *jsonParser = [SBJSON new];
    NSDictionary *dictResponse = [jsonParser objectWithString:response];
    NSDictionary *dictResult = [dictResponse objectForKey:@"result"];
    
    NSDecimalNumber *resultCode = [dictResult objectForKey:@"code"];
    if (resultCode != nil && [resultCode intValue] != 0) {
        if (dictResult != nil && [[dictResult objectForKey:@"code"] intValue] == -1) {
            NSLog(@"Asynch request said, auth token is invalid. Getting a new one.");
            [self authWithUsername:self.username password:self.password];
        }
    }
}

#pragma mark Private methods

- (NSData *) getDataAsNSData:(NSString *)URL {
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
	NSError *error = nil;
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
	return data;
}

- (NSDictionary *) getAndParse:(ASIFormDataRequest *)request {
    NSError *error = [request error];
    NSDictionary *result = nil;
    if (!error) {
        NSString *response = [request responseString];
        SBJSON *jsonParser = [SBJSON new];
        NSDictionary *dictResponse = [jsonParser objectWithString:response];
        NSDictionary *dictResult = [dictResponse objectForKey:@"result"];
        NSDictionary *dictData = [dictResponse objectForKey:@"data"];
        
        NSDecimalNumber *resultCode = [dictResult objectForKey:@"code"];
        if (resultCode != nil && [resultCode intValue] == 0) {
            result = dictData;
        } else {
            if (dictResult != nil) {
                NSLog(@"Unable to execute Eightdigits API command. Error: %@", [dictResult objectForKey:@"message"]);
                if ([[dictResult objectForKey:@"code"] intValue] == -1) {
                    NSLog(@"Sync method said auth token is invalid. Getting a new one and retrying....");
                    [self authWithUsername:self.username password:self.password];
                    [NSException raise:@"Authentication needed." format:@"Auth token %@ is invalid", self.authToken];
                }
            } else {
                NSLog(@"Unable to execute Eightdigits API command.");
            }
        }
    }
    return result;
}

#pragma mark Memory management

- (void)dealloc {
    [authToken release];
    [visitorCode release];
    [trackingCode release];
    [sessionCode release];
    [urlPrefix release];
    [username release];
    [password release];
    [super dealloc];
}


@end
