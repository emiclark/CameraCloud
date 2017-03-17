//
//  LoginViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/22/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GalleryCollectionViewController.h"
#import "DAO.h"

@import Firebase;
@import FirebaseAuth;

@interface LoginViewController : UIViewController

@property (strong, nonatomic)   DAO  *dao;
@property (strong, nonatomic) GalleryCollectionViewController *galleryVC;
@property (weak, nonatomic)   FIRAuth  *handle;
@property (weak, nonatomic)   NSString *currentUser;

@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *userEmail;
@property (weak, nonatomic) IBOutlet UITextField *userPassword;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;


- (IBAction)createAccount:(UIButton *)sender;
- (IBAction)loginButtonTapped:(UIButton *)sender;
- (IBAction)logoutButtonTapped:(UIButton *)sender;

- (void) saveLoginInfoToUserDefaults;
-(void) showAlertTitle: (NSString *)alertTitle andMsg:(NSString *) msg;

@end
