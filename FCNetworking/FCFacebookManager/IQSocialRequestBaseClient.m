//
//  IQSocialRequestBaseClient.m
//  Qramid
//
//  Created by Kanybek Momukeev on 3/28/13.
//  Copyright (c) 2013 Kanybek Momukeev. All rights reserved.
//

#import "IQSocialRequestBaseClient.h"
#import "AFJSONRequestOperation.h"
#import "AFNetworkActivityIndicatorManager.h"

static NSString * const kAPIBaseURLString = @"https://graph.facebook.com";

@implementation IQSocialRequestBaseClient
+ (IQSocialRequestBaseClient *)sharedClient {
    static  IQSocialRequestBaseClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[IQSocialRequestBaseClient alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
        [_sharedClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    });
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    return _sharedClient;
}


- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    return self;
}
@end
