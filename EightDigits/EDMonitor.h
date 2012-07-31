//
//  EDMonitor.h
//  EightDigits
//
//  Created by Seyithan Teymur on 22/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDClassInfo : NSObject

@property (nonatomic, copy)					NSString	*title;
@property (nonatomic, copy)					NSString	*path;
@property (nonatomic, getter = isAutomatic)	BOOL		 automatic;

@property (nonatomic, assign)				Class		 class;
@property (nonatomic, copy)					NSString	*className;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface EDMonitor : NSObject

+ (EDMonitor *)defaultMonitor;

- (EDClassInfo *)classInfoForClass:(Class)class;

@end
