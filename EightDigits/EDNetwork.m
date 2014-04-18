    //
//  EDNetwork.m
//  EightDigitsTest
//
//  Created by Halil Gursoy on 10/04/14.
//  Copyright (c) 2014 Verisun Bilişim Danışmanlık. All rights reserved.
//

#import "EDNetwork.h"
#import "ED_ARC.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000

@implementation AFHTTPClient(EDNetworkAdditions)


typedef void (^AFNetworkReachabilityStatusBlock)(AFNetworkReachabilityStatus status);
static const void * AFNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void AFNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}


typedef enum : NSInteger {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
} NetworkStatus;

@end

#endif

@interface EDNetwork()

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000

@property (nonatomic, strong)            AFHTTPClient                 * httpClient;
@property (readwrite, nonatomic, assign) SCNetworkReachabilityRef       networkReachability;

#else


@property (nonatomic, strong) AFHTTPRequestOperationManager *afManager;

#endif

@property (nonatomic, copy) void  (^reachabilityBlock)(BOOL);
@end

@implementation EDNetwork

#if !__has_feature(objc_arc)
- (void)dealloc {

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
    [_httpClient release];
#else
    [_afManager release];
#endif
    
    
}

#endif

+(EDNetwork *)sharedInstance {
    static EDNetwork * _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,  ^ {
        _sharedInstance = [[EDNetwork alloc] init];
        _sharedInstance.queue = [[EDOperationQueue alloc] init];
        _sharedInstance.reachabilityBlock = ^(BOOL isReachable) {
        };
    });
    return _sharedInstance;
}


#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000


-(void)setBaseURL:(NSString *)baseURL {
    _baseURL = baseURL;
    if(_httpClient)
        ED_ARC_RELEASE(_httpClient);
    
    _httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:_baseURL]];
    _httpClient.parameterEncoding = AFFormURLParameterEncoding;
    
//    __weak EDNetwork *weakSelf = self;
    
//    [_httpClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
//        if(status == AFNetworkReachabilityStatusReachableViaWWAN ||
//           status == AFNetworkReachabilityStatusReachableViaWiFi) {
//            if(weakSelf.reachabilityBlock)
//                weakSelf.reachabilityBlock(YES);
//            
//            NSLog(@"Network reachable");
//        }
//        else {
//            if(weakSelf.reachabilityBlock)
//                weakSelf.reachabilityBlock(NO);
//            NSLog(@"Network not reachable");
//        }
//
//    }];
}

- (void)postRequest:(NSString *)path params:(NSDictionary *)params completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock {
    
    [self baseRequest:path type:@"POST" params:params returning:NO completionBlock:completionBlock failBlock:failBlock ];
}

- (void)getRequest:(NSString *)path params:(NSDictionary *)params completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock {
    [self baseRequest:path type:@"GET" params:params returning:NO completionBlock:completionBlock failBlock:failBlock ];
}

- (AFHTTPRequestOperation *)baseRequest:(NSString *)path type:(NSString *)type params:(NSDictionary *)params returning:(BOOL)returning completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock  {
    
    AFHTTPRequestOperation *operation;
    
//    if(_httpClient.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN ||
//        _httpClient.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi) {
    
        
        
        NSMutableURLRequest *request = [_httpClient requestWithMethod:type
                                                          path:path
                                                    parameters:params];
        [request setTimeoutInterval:100];
        operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (completionBlock)
                completionBlock([EDNetwork parseDataAsJSON:responseObject]);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failBlock)
                failBlock(error);
        }];
    
        ED_ARC_RELEASE(request);
    
        if(!returning)
            [operation start];
//    }
//    else {
////        [self showConnectionError:block];
//    }
    
    return operation;
    
}

- (void)addRequestToQueue:(NSString *)path type:(NSString *)type params:(NSDictionary *)params priority:(NSOperationQueuePriority)priority completionBlock:(void (^)(id responseObject))completionBlock failBlock:(void (^)(NSError *error))failBlock {
    
    AFHTTPRequestOperation *operation = [self baseRequest:path type:type params:params returning:YES completionBlock:completionBlock failBlock:failBlock ];
    [self.queue addOperation:operation];
    
}


//- (void)startMonitoringNetworkReachability {
//    [self stopMonitoringNetworkReachability];
//    
//    if (!self.baseURL) {
//        return;
//    }
//    
//    self.networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [[[NSURL URLWithString:self.baseURL] host] UTF8String]);
//    
//    if (!self.networkReachability) {
//        return;
//    }
//    
//    __weak __typeof(&*self)weakSelf = self;
//    AFNetworkReachabilityStatusBlock callback = ^(AFNetworkReachabilityStatus status) {
//        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
//        if (!strongSelf) {
//            return;
//        }
//        
////        strongSelf.networkReachabilityStatus = status;
//        if (strongSelf.reachabilityBlock) {
//            strongSelf.reachabilityBlock(status);
//        }
//    };
//    
//    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, AFNetworkReachabilityRetainCallback, AFNetworkReachabilityReleaseCallback, NULL};
//    SCNetworkReachabilitySetCallback(self.networkReachability, AFNetworkReachabilityCallback, &context);
//    
//    /* Network reachability monitoring does not establish a baseline for IP addresses as it does for hostnames, so if the base URL host is an IP address, the initial reachability callback is manually triggered.
//     */
//    if (AFURLHostIsIPAddress(self.baseURL)) {
//        SCNetworkReachabilityFlags flags;
//        SCNetworkReachabilityGetFlags(self.networkReachability, &flags);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            AFNetworkReachabilityStatus status = AFNetworkReachabilityStatusForFlags(flags);
//            callback(status);
//        });
//    }
//    
//    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
//}
//
//- (void)stopMonitoringNetworkReachability {
//    if (self.networkReachability) {
//        SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
//        
//        CFRelease(_networkReachability);
//        _networkReachability = NULL;
//    }
//}


- (void)monitorReachability:(void (^)(BOOL))reachabilityBlock {
    
//    AFNetworkReachabilityStatus status = _httpClient.networkReachabilityStatus;
//    if(status == AFNetworkReachabilityStatusReachableViaWWAN ||
//       status == AFNetworkReachabilityStatusReachableViaWiFi) {
//        if(reachabilityBlock)
//            reachabilityBlock(YES);
//        
//        NSLog(@"Network reachable");
//    }
//    else {
//        if(reachabilityBlock)
//            reachabilityBlock(NO);
//        NSLog(@"Network not reachable");
//    }
    
    
//    self.baseURL = [_httpClient.baseURL absoluteString];
    
//    reachabilityBlock(YES);
    
    self.reachabilityBlock = reachabilityBlock;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    

//    [_httpClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
//        if(status == AFNetworkReachabilityStatusReachableViaWWAN ||
//           status == AFNetworkReachabilityStatusReachableViaWiFi) {
//            if(reachabilityBlock)
//                reachabilityBlock(YES);
//            
//            NSLog(@"Network reachable");
//        }
//        else {
//            if(reachabilityBlock)
//                reachabilityBlock(NO);
//            NSLog(@"Network not reachable");
//        }
//    }];
}

- (void)reachabilityChanged:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    AFNetworkReachabilityStatus status = [dict[AFNetworkingReachabilityNotificationStatusItem] integerValue];
    if(status == AFNetworkReachabilityStatusReachableViaWWAN ||
       status == AFNetworkReachabilityStatusReachableViaWiFi) {
        if(_reachabilityBlock)
            _reachabilityBlock(YES);
        
    }
    else {
        if(_reachabilityBlock)
            _reachabilityBlock(YES);
    }

}


#else



- (void)setBaseURL:(NSString *)baseURL {
    _baseURL    = baseURL;
    if(_afManager) {
        ED_ARC_RELEASE(_afManager);
        _afManager = nil;
    }
    _afManager  = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:_baseURL]];
    _afManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    _afManager.requestSerializer  = [AFHTTPRequestSerializer serializer] ;
}

- (void)getRequest:(NSString *)path params:(NSDictionary *)params completionBlock:(void (^)(id))completionBlock failBlock:(void (^)(NSError *))failBlock {
    [_afManager GET:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(completionBlock) {
            completionBlock([EDNetwork parseDataAsJSON:responseObject]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failBlock)
            failBlock(error);
    }];
}

- (void)postRequest:(NSString *)path params:(NSDictionary *)params completionBlock:(void (^)(id))completionBlock failBlock:(void (^)(NSError *))failBlock {
    [_afManager POST:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(completionBlock)
            completionBlock([EDNetwork parseDataAsJSON:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failBlock)
            failBlock(error);
    }];
}

- (AFHTTPRequestOperation *)baseRequest:(NSString *)path type:(NSString *)type params:(NSDictionary *)params returning:(BOOL)returning completionBlock:(void (^)(id))completionBlock failBlock:(void (^)(NSError *))failBlock  {
    NSMutableURLRequest *request = [_afManager.requestSerializer requestWithMethod:type URLString:[NSString stringWithFormat:@"%@%@", _afManager.baseURL, path] parameters:params error:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(completionBlock)
            completionBlock([EDNetwork parseDataAsJSON:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failBlock)
            failBlock(error);
    }];
    return operation;

}

- (void)addRequestToQueue:(NSString *)path type:(NSString *)type params:(NSDictionary *)params priority:(NSOperationQueuePriority)priority completionBlock:(void (^)(id))completionBlock failBlock:(void (^)(NSError *))failBlock {
    NSMutableURLRequest *request = [_afManager.requestSerializer requestWithMethod:type URLString:[NSString stringWithFormat:@"%@%@", _afManager.baseURL, path] parameters:params error:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(completionBlock)
            completionBlock([EDNetwork parseDataAsJSON:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failBlock)
            failBlock(error);
    }];
    [self.queue addOperation:operation];
    [self.queue go];
}

- (void)monitorReachability:(void (^)(BOOL))reachabilityBlock {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if(status == AFNetworkReachabilityStatusReachableViaWiFi ||
           status == AFNetworkReachabilityStatusReachableViaWWAN) {
            if(reachabilityBlock)
                reachabilityBlock(YES);
        }
        else {
            if(reachabilityBlock)
                reachabilityBlock(NO);
        }
    }];
}

#endif

+ (id) parseDataAsJSON:(NSData *) data {
    if (!data)
        return nil;
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

@end

@implementation EDOperationQueue

- (id)init {
    self = [super init];
    if(self) {
        [self addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
    
    return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"operations"]) {
        if ([self.operations count] == 0) {
            // Do something here when your queue has completed
            if(_delegate && [_delegate respondsToSelector:@selector(queueDidFinish)])
                [_delegate queueDidFinish];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}


-(void)go {
    [self setSuspended:NO];
}

@end
