//
//  EightdigitsClient.m
//
//  Copyright (c) 2012 8digits.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EightdigitsClient : NSObject {
    NSString *urlPrefix;
    NSString *authToken;
    NSString *trackingCode;
    NSString *visitorCode;
    NSString *sessionCode;
    NSString *username;
    NSString *password;
}
@property (nonatomic, retain) NSString *urlPrefix;
@property (nonatomic, retain) NSString *trackingCode;
@property (nonatomic, retain) NSString *authToken;
@property (nonatomic, retain) NSString *visitorCode;
@property (nonatomic, retain) NSString *sessionCode;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

- (id)initWithUrlPrefix:(NSString *)urlPrefix trackingCode:(NSString *)trackingCode;
- (void)authWithUsername:(NSString *)username password:(NSString *)password;
- (NSString *)newVisitWithTitle:(NSString *)title path:(NSString *)path;
- (void)endScreenWithHitCode:(NSString *)hitCode;
- (void)eventWithKey:(NSString *)key value:(NSString *)value hitCode:(NSString *)hitCode;
- (void)endVisit;
- (NSString *)newScreenWithTitle:(NSString *)title path:(NSString *)path;
- (NSInteger)score;
- (NSArray *)badges;
- (UIImage *)badgeImageForId:(NSString *)badgeId;

@end
