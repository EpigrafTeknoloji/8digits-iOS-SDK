//
//  EDHit.h
//  EightDigits
//
//  Created by Seyithan Teymur on 24/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EDVisit;

/**
	8digits hit
	Represents a screen. All UIViewController objects have an EDHit object. 
 */
@interface EDHit : NSObject <NSCoding>

/**
	The visit that manages this object 
	@default [EDVisit currentVisit]
 */
@property (nonatomic, assign)							EDVisit		*visit;

/**
	Hit code
 */
@property (nonatomic, strong, readonly)					NSString	*hitCode;


/**
	The title of the hit
	Usually the title property of the UIViewController object that owns the hit.
	This property can be set directly within EDHits dictionary inside EightDigits.plist per controller as the value for EDTitle key.
 */
@property (nonatomic, copy)								NSString	*title;

/**
	The path of the hit
	Usually the class name of the UIViewController object that owns the hit.
	This property can be set directly within EDHits dictionary inside EightDigits.plist per controller as the value for EDPath key.
 */
@property (nonatomic, copy)								NSString	*path;

- (void)setTitle:(NSString *)title path:(NSString *)path;

/**
	Registration status
 */
@property (nonatomic, readonly, getter = isRegistered)	BOOL		 registered;

/**
	All non-registered EDEvent objects belonging to this hit
	All events inside this array have either failed to register or haven't finished yet. The reason for this might be an unreachable network, a failed authorisation or a yet unregistered hit.
 */
@property (nonatomic, strong, readonly)					NSArray		*events;

/**
	Start date of the hit
	Set internally when start method is called.
 */
@property (nonatomic, strong, readonly)					NSDate		*startDate;

/**
	End date of the hit
	Set internally when end method is called.
 */
@property (nonatomic, strong, readonly)					NSDate		*endDate;


/**
	Designated initialiser for controller
	@param controller The controller to which this hit will belong. The hit's title will be the controller's title and path will be the controller's class name.
 */
- (id)initWithController:(UIViewController *)controller;


/**
	Starts the hit
	Usually called inside UIViewController object's viewWillAppear method.
 */
- (void)start;

/**
	Ends the hit
	Usually called inside UIViewController object's viewWillDisappear method
 */
- (void)end;


@end


@interface UIViewController (EDHitAdditions)

/**
	The hit belonging to this controller
	If not set, or ended; creates a new EDHit and returns it.
 */
@property (nonatomic, strong)	EDHit		*hit;

/**
	The hit code of the hit belonging to this controller
	@see hit
 */
@property (nonatomic, readonly)	NSString	*hitCode;


@end
