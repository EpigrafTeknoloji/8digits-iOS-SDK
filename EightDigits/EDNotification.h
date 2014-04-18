//
//  EDNotification.h
//  8DigitsExample
//
//  Created by skizilkaya on 27.02.2014.
//  Copyright (c) 2014 skizilkaya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDNotification : NSObject
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * details;
@property (nonatomic, strong) NSString * imageURL;
@property (nonatomic, strong) NSString * buttonText;

- (id)initWithDictionary:(NSDictionary *)dict;

+ (void)checkAndShowNotifications;


@end
