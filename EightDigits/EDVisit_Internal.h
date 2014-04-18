//
//  EDVisit_Internal.h
//  EightDigits
//
//  Created by Seyithan Teymur on 28/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDVisit.h"

//@class ASINetworkQueue;
//@class ASIHTTPRequest;

@class EDHit;
@class EDEvent;

@protocol EDVisitValidationDelegate;

@interface EDVisit ()

//@property (nonatomic, strong)	ASINetworkQueue					*networkQueue;
@property (nonatomic, assign)	id <EDVisitValidationDelegate>	 validationDelegate;

- (void)validate;
- (void)addRequest:(AFHTTPRequestOperation *)request;

- (void)hitWillStart:(EDHit *)hit;
- (void)hitDidStart:(EDHit *)hit;

- (void)hitWillEnd:(EDHit *)hit;
- (void)hitDidEnd:(EDHit *)hit;

- (void)eventWillTrigger:(EDEvent *)event;
- (void)eventDidTrigger:(EDEvent *)event;

- (void)logMessage:(NSString *)format,...;
- (void)logWarning:(NSString *)warning;
- (void)logError:(NSString *)error;


@end

@protocol EDVisitValidationDelegate <NSObject>

- (void)visit:(EDVisit *)visit didGetValidatedSuccessfully:(BOOL)successful;
- (void)visitDidFailPermanently:(EDVisit *)visit;

@end
