//
//  NetworkService.h
//  Azure Maps
//
//  Created by Claus Höfele on 13.05.14.
//  Copyright (c) 2014 Claus Höfele. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WindowsAzureMobileServices/WindowsAzureMobileServices.h>

@interface UserService : NSObject

+ (instancetype)sharedService;

- (void)registerUserWithName:(NSString *)name password:(NSString *)password completion:(MSItemBlock)completion;
- (void)loginUserWithName:(NSString *)name password:(NSString *)password completion:(MSClientLoginBlock)completion;
- (void)autoLoginWithCompletion:(MSClientLoginBlock)completion;

@end
