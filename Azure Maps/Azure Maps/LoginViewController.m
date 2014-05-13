//
//  LoginViewController.m
//  Azure Maps
//
//  Created by Claus Höfele on 13.05.14.
//  Copyright (c) 2014 Claus Höfele. All rights reserved.
//

#import "LoginViewController.h"

#import "UserService.h"
#import "MAKRAzureMapsService.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *signInUserTextField;
@property (weak, nonatomic) IBOutlet UITextField *signInPasswordTextField;

@property (weak, nonatomic) IBOutlet UITextField *signUpUserTextField;
@property (weak, nonatomic) IBOutlet UITextField *signUpPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *signUpPasswordConfirmTextField;

@property (nonatomic) UserService *userService;
@property (nonatomic) MAKRAzureMapsService *mapsService;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userService = [UserService sharedService];
    self.mapsService = [MAKRAzureMapsService sharedService];
}

- (IBAction)signIn
{
    NSString *userName = self.signInUserTextField.text;
    NSString *password = self.signInPasswordTextField.text;
    if (userName.length > 0 && password.length > 0) {
        [self.userService loginUserWithName:userName password:password completion:^(MSUser *user, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                self.mapsService.client.currentUser = user;
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    }
}

- (IBAction)signUp
{
    NSString *userName = self.signUpUserTextField.text;
    NSString *password = self.signUpPasswordTextField.text;
    NSString *passwordConfirm = self.signUpPasswordConfirmTextField.text;
    if (userName.length > 0 && password.length > 0 && [password isEqualToString:passwordConfirm]) {
        [self.userService registerUserWithName:userName password:password completion:^(NSDictionary *item, NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    }
}

@end
