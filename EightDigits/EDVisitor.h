//
//  EDVisitor.h
//  EightDigits
//
//  Created by Seyithan Teymur on 28/07/12.
//  Copyright (c) 2012 Epigraf. All rights reserved.
//

#import <Foundation/Foundation.h>

enum _EDVisitorScore {
	EDVisitorScoreNotLoaded = NSIntegerMax
};

@class EDVisit;

@interface EDVisitor : NSObject

/**
	Currently authenticated visitor
	nil if visit has not authenticated yet
 */
+ (EDVisitor *)currentVisitor;

@property (nonatomic, assign, readonly)	EDVisit		*visit;


/**
	Visitor code
 */
@property (nonatomic, strong, readonly)	NSString	*visitorCode;

/**
	Array of badge identifiers of badges of the visitor
	nil until loadBadgesWithCompletionHandler: has completed
 */
@property (nonatomic, strong, readonly) NSArray		*badges;

/**
	Asynchronously loads the visitor badges as an array of badge identifiers. Calls completionHandler when complete. Error will be nil on success.
 */
- (void)loadBadgesWithCompletionHandler:(void(^)(NSArray *badges, NSString *error))completionHandler;

/**
	Returns the url for the image of a badge
	@param badgeID The identifier of the badge
 */
- (NSURL *)urlForImageForBadgeWithID:(NSString *)badgeID;

/**
	Visitor score of the visitor
	Equals to EDVisitorScoreNotLoaded until loadScoreWithCompletionHandler:, increaseScoreBy:withCompletionHandler: or decreaseScoreBy:withCompletionHandler: has completed. Either one of these methods updates the score property.
 */
@property (nonatomic, assign, readonly)	NSInteger	 score;

/**
	Asynchronously loads the visitor score as an array of badge identifiers. Calls completionHandler when complete. Error will be nil on success.
 */
- (void)loadScoreWithCompletionHandler:(void(^)(NSInteger score, NSString *error))completionHandler;

/**
	Asynchronously increases visitor score by differential
	Calls completionHandler when complete. Error will be nil on success.
 */
- (void)increaseScoreBy:(NSInteger)differential withCompletionHandler:(void(^)(NSInteger newScore, NSString *error))completionHandler;

/**
	Asynchronously decreases visitor score by differential
	Calls completionHandler when complete. Error will be nil on success.
 */
- (void)decreaseScoreBy:(NSInteger)differential withCompletionHandler:(void(^)(NSInteger newScore, NSString *error))completionHandler;


@end
