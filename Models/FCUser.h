//
//  FCUser.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>

@interface FCUser : NSObject

- (id)initWithDict:(NSDictionary *)dict;

@property (nonatomic, strong, readonly) NSString *userId;
@property (nonatomic, strong, readonly) NSString *name;

@end
