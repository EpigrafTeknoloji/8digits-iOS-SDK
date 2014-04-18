//
//  EDMonitor.m
//  EightDigits
//
//  Created by Seyithan Teymur on 22/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import "EDMonitor.h"
#import "EDHit.h"

#import "ED_ARC.h"

#import <objc/runtime.h>

@implementation EDClassInfo

@synthesize title		= _title;
@synthesize path		= _path;
@synthesize automatic	= _automatic;

@synthesize class		= _class;
@synthesize className	= _className;

#if !__has_feature(objc_arc)
- (void)dealloc {
	
	[_title release];
	[_path release];
	[_className release];
	
	[super dealloc];
	
}
#endif

- (id)initWithDictionary:(NSDictionary *)dictionary {
	
	self = [super init];
	
	if (self) {
		self.title = [dictionary objectForKey:@"EDTitle"];
		self.path = [dictionary objectForKey:@"EDPath"];
		self.automatic = [[dictionary objectForKey:@"EDAutomaticMonitoring"] boolValue];
		
		self.className = [dictionary objectForKey:@"EDClassName"];
		self.class = NSClassFromString(self.className);
	}
	
	return self;
	
}

@end

@interface EDMonitor ()

@property (nonatomic, strong)	NSDictionary	*monitoredClasses;

- (void)swapImplementations;

- (void)controllerDidAppear:(UIViewController *)controller;
- (void)controllerDidDisappear:(UIViewController *)controller;

@end

static EDMonitor	*_defaultMonitor = nil;

id (*originalAppear)(id, SEL, BOOL);
id (*originalDisappear)(id, SEL, BOOL);

static id newAppear(id self, SEL _cmd, BOOL animated) {
	
	
	if ([self isKindOfClass:[UIViewController class]]) {
		[[EDMonitor defaultMonitor] controllerDidAppear:self];
	}
	
	return nil;
	
}

static id newDisappear(id self, SEL _cmd, BOOL animated) {
	
	if ([self isKindOfClass:[UIViewController class]]) {
		[[EDMonitor defaultMonitor] controllerDidDisappear:self];
	}
	
	return nil;
	
}

@implementation EDMonitor

@synthesize monitoredClasses	= _monitoredClasses;

+ (EDMonitor *)defaultMonitor {
	
	if (_defaultMonitor == nil) {
		_defaultMonitor = [[EDMonitor alloc] init];
		[_defaultMonitor swapImplementations];
	}
	
	return _defaultMonitor;
	
}

- (id)init {
	
	self = [super init];
	
	if (self) {
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"EightDigits" ofType:@"plist"];
		NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
		
		NSArray *array = [dict objectForKey:@"EDHits"];
		NSMutableDictionary *monitoredClasses = [[NSMutableDictionary alloc] init];
		
		for (NSDictionary *monitorDict in array) {
			
			EDClassInfo *info = [[EDClassInfo alloc] initWithDictionary:monitorDict];
			
			if (info.className == nil) {
				ED_ARC_RELEASE(info);
				continue;
			}
			
			[monitoredClasses setObject:info forKey:info.className];
			
			ED_ARC_RELEASE(info);
			
		}
		
		self.monitoredClasses = monitoredClasses;
		
		ED_ARC_RELEASE(monitoredClasses);
		ED_ARC_RELEASE(dict);
		
	}
	
	return self;
	
}

- (void)swapImplementations {
	
	Method originalAppearance = class_getInstanceMethod([UIViewController class], @selector(viewWillAppear:));
	originalAppear = (void *)method_getImplementation(originalAppearance);
	method_setImplementation(originalAppearance, (IMP)newAppear);
	
	Method originalDisappearance = class_getInstanceMethod([UIViewController class], @selector(viewWillDisappear:));
	originalDisappear = (void *)method_getImplementation(originalDisappearance);
	method_setImplementation(originalDisappearance, (IMP)newDisappear);
	
}

#pragma mark -

- (EDClassInfo *)classInfoForClass:(Class)class {
	return [self.monitoredClasses objectForKey:NSStringFromClass(class)];
}

- (void)controllerDidAppear:(UIViewController *)controller {
	EDClassInfo *info = [[EDMonitor defaultMonitor] classInfoForClass:[controller class]];
	if (info.automatic) {
		[controller.hit start];
	}
}

- (void)controllerDidDisappear:(UIViewController *)controller {
	EDClassInfo *info = [[EDMonitor defaultMonitor] classInfoForClass:[controller class]];
	if (info.automatic) {
		[controller.hit end];
	}
}

@end
