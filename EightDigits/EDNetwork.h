//
//  EDNetwork.h
//  EightDigitsTest
//
//  Created by Halil Gursoy on 10/04/14.
//  Copyright (c) 2014 Verisun Bilişim Danışmanlık. All rights reserved.
//



#import <Foundation/Foundation.h>

#import "AFNetworking.h"

@class EDOperationQueue;

@interface EDNetwork : NSObject

@property (nonatomic, strong) NSString              * baseURL;
@property (nonatomic, strong) EDOperationQueue      * queue;

+(EDNetwork *) sharedInstance;

- (void)postRequest:(NSString *)path params:(NSDictionary *)params completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock;

- (void)getRequest:(NSString *)path params:(NSDictionary *)params completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock;

- (void)addRequestToQueue:(NSString *)path type:(NSString *)type params:(NSDictionary *)params priority:(NSOperationQueuePriority)priority completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock;

- (AFHTTPRequestOperation *)baseRequest:(NSString *)path type:(NSString *)type params:(NSDictionary *)params returning:(BOOL)returning completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock ;

- (void)monitorReachability:(void (^)(BOOL reachable))reachabilityBlock;


@end

@protocol EDOperationQueueDelegate <NSObject>

- (void)queueDidFinish;

@end


@interface EDOperationQueue : NSOperationQueue

@property (nonatomic, weak) id<EDOperationQueueDelegate> delegate;

- (void)go;

@end

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000

@interface AFHTTPClient (EDNetworkAdditions)

@end

#endif










