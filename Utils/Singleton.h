//
//  Singleton.h
//  My_Menu_1
//
//  Created by Andrey Kladov on 05.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

/*!
 * @function Singleton GCD Macro
 */
#ifndef SINGLETON_GCD
#define SINGLETON_GCD(classname)                        \
\
+ (classname *)sharedInstance {                      \
\
static dispatch_once_t pred;                        \
__strong static classname * shared##classname = nil;\
dispatch_once( &pred, ^{                            \
shared##classname = [[self alloc] init]; });    \
return shared##classname;                           \
}                                                           
#endif