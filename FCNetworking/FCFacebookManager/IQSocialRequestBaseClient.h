//
//  IQSocialRequestBaseClient.h
//  Qramid
//
//  Created by Kanybek Momukeev on 3/28/13.
//  Copyright (c) 2013 Kanybek Momukeev. All rights reserved.
//


#import "AFHTTPClient.h"
@interface IQSocialRequestBaseClient : AFHTTPClient
+ (IQSocialRequestBaseClient *)sharedClient;
@end
