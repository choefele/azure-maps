//
//  DataService.m
//  Azure Maps
//
//  Created by Claus Höfele on 13.05.14.
//  Copyright (c) 2014 Claus Höfele. All rights reserved.
//

#import "UserService.h"

#define URL_STRING @"https://azure-maps.azure-mobile.net/"
#define APPLICATION_KEY @"GRUVwdzPgkUVneHJRJntAHFoUmEAbe95"
#define USER_ID_KEY @"userID"
#define USER_TOKEN_KEY @"token"

@interface UserService()<MSFilter>

@property (nonatomic) MSClient *client;

@end

@implementation UserService

- (id)init
{
    self = [super init];
    if (self) {
        self.client = [MSClient clientWithApplicationURLString:URL_STRING applicationKey:APPLICATION_KEY];
    }
    
    return self;
}

+ (instancetype)sharedService
{
    static UserService* service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[UserService alloc] init];
    });
    
    return service;
}

- (void)handleRequest:(NSURLRequest *)request next:(MSFilterNextBlock)next response:(MSFilterResponseBlock)response
{
    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    NSURL *newURL;
    if ([mutableRequest.URL.absoluteString rangeOfString:@"?"].location != NSNotFound) {
        newURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", mutableRequest.URL.absoluteString, @"&login=true"]];
    } else {
        newURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", mutableRequest.URL.absoluteString, @"?login=true"]];
    }
    
    mutableRequest.URL = newURL;
    next(mutableRequest, response);
}

- (void)registerUserWithName:(NSString *)name password:(NSString *)password completion:(MSItemBlock)completion
{
    MSTable *accounts = [self.client tableWithName:@"accounts"];
    NSDictionary *account = @{ @"name": name, @"password": password };
    [accounts insert:account completion:completion];
}

- (void)loginUserWithName:(NSString *)name password:(NSString *)password completion:(MSClientLoginBlock)completion
{
    MSClient *loginClient = [self.client clientWithFilter:self];
    MSTable *accounts = [loginClient tableWithName:@"accounts"];
    NSDictionary *credentials = @{ @"name": name, @"password": password };
    [accounts insert:credentials completion:^(NSDictionary *item, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            NSString *userID = [item valueForKeyPath:@"user.userId"];
            NSString *token = item[@"token"];
            
            MSUser *user = [[MSUser alloc] initWithUserId:userID];
            user.mobileServiceAuthenticationToken = token;
            self.client.currentUser = user;
            
            [NSUserDefaults.standardUserDefaults setObject:userID forKey:USER_ID_KEY];
            [NSUserDefaults.standardUserDefaults setObject:token forKey:USER_TOKEN_KEY];
            [NSUserDefaults.standardUserDefaults synchronize];
            
            completion(user, nil);
        }
    }];
}

- (void)autoLoginWithCompletion:(MSClientLoginBlock)completion
{
    NSString *userID = [NSUserDefaults.standardUserDefaults stringForKey:USER_ID_KEY];
    NSString *token = [NSUserDefaults.standardUserDefaults stringForKey:USER_TOKEN_KEY];
    if (userID && token) {
        MSUser *user = [[MSUser alloc] initWithUserId:userID];
        user.mobileServiceAuthenticationToken = token;
        self.client.currentUser = user;
        
        completion(user, nil);
    } else {
        completion(nil, [NSError errorWithDomain:@"autoLoginWithCompletion" code:0 userInfo:nil]);
    }
}

@end
