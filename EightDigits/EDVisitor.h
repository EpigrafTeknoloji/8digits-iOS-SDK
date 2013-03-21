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

typedef enum _EDVisitorGender {

    EDVisitorGenderNotSpecified = 0,
    
    EDVisitorGenderMale,
    EDVisitorGenderFemale    
    
} EDVisitorGender;

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
- (void)loadVisitorBadgesWithCompletionHandler:(void(^)(NSArray *badges, NSString *error))completionHandler;

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


/**
	Full name of the visitor. 
    Sets fullName as visitor attribute value for key: fullName.
    Will be sent to 8digits servers as soon as set. Also kept locally once successfully sent to servers. You can check and overwrite only if nil.
    @see setVisitorAttributeValue:forKey:
 */
@property (nonatomic, strong)           NSString            *fullName;

/**
	Gender of the visitor.
    Sets M for male and F for female as visitor attribute value for key: gender.
    Will be sent to 8digits servers as soon as set to either EDVisitorGenderMale or EDVisitorGenderFemale. Also kept locally once successfully sent to servers. You can check and overwrite only if EDVisitorGenderNotSpecified.
    @see setVisitorAttributeValue:forKey:
 */
@property (nonatomic, assign)           EDVisitorGender      gender;

/**
	Age of the visitor.
    Sets age as visitor attribute value for key: age.
    Will be sent to 8digits servers as soon as set to any positive integer. Also kept locally once successfully sent to servers. You can check and overwrite only if 0.
     @see setVisitorAttributeValue:forKey:
 */
@property (nonatomic, assign)           NSInteger            age;

/**
	Avatar path of the visitor.
    Sets avatarPath as visitor attribute value for key: avatarPath.
    Will be sent to 8digits servers as soon as set. Also kept locally once successfully sent to servers. You can check and overwrite only if nil.
     @see setVisitorAttributeValue:forKey:
 */
@property (nonatomic, strong)           NSString            *avatarPath;

/**
	Adds visitor attribute information from given dictionary.
    The attribute information will be sent to 8digits servers immediately. The information will also be kept locally once successfully sent to servers.
    Calls completionHandler when complete. Error will be nil on success.
	@param dictionary The dictionary that contains the attribute keys and values.
 */
- (void)setVisitorAttributesFromDictionary:(NSDictionary *)dictionary withCompletionHandler:(void(^)(NSString *error))completionHandler;
    
/**
	Visitor attributes that are successfully sent to 8digits servers for this visitor.
    Contains fullName, age, gender or avatarPath along with custom key-value pairs if set.
 */
@property (nonatomic, readonly)         NSDictionary        *visitorAttributes;


@end
