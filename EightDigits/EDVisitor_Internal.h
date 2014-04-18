//
//  EDVisitor_Internal.h
//  EightDigits
//
//  Created by Seyithan Teymur on 29/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDVisitor.h"

@interface EDVisitor ()

@property (nonatomic, assign, readwrite)	EDVisit		*visit;
@property (nonatomic, strong, readwrite)	NSString	*visitorCode;

+ (void)setCurrentVisitor:(EDVisitor *)visitor;

@end
