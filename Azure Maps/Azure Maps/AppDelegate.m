//
//  AppDelegate.m
//  Azure Maps
//
//  Created by Claus Höfele on 13.05.14.
//  Copyright (c) 2014 Claus Höfele. All rights reserved.
//

#import "AppDelegate.h"

#import "UserService.h"
#import "MAKRAzureMapsService.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UserService *userService = [UserService sharedService];
    [userService autoLoginWithCompletion:^(MSUser *user, NSError *error) {
        if (error) {
            NSLog(@"Auto login failed");
        } else {
            MAKRAzureMapsService *mapsService = [MAKRAzureMapsService sharedService];
            mapsService.client.currentUser = user;

            NSLog(@"Auto login succeeded");
        }
    }];

    return YES;
}

@end
