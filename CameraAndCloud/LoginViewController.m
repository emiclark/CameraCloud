//
//  LoginViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/22/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "LoginViewController.h"

#define BASE_URL @"https://cameraandcloud-935e4.firebaseio.com/"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.galleryVC = [[GalleryCollectionViewController alloc] init];
    self.galleryVC.isLoggedOut = NO;
    
    // set dark orange color
    UIColor *myOrangeColor = [UIColor colorWithRed:236/255 green:83/255 blue: 6/255 alpha:1];

    self.createAccountButton.titleLabel.textColor = myOrangeColor;
    [[self.createAccountButton layer] setBorderWidth: 1.0f];
    [[self.createAccountButton layer] setBorderColor: myOrangeColor.CGColor];
    
    self.logoutButton.titleLabel.textColor = myOrangeColor;
    [[self.logoutButton layer] setBorderWidth: 1.0f];
    [[self.logoutButton layer] setBorderColor: myOrangeColor.CGColor];
    [[self.logoutButton layer] setCornerRadius: 4.0f];
    
    // get root reference in Database
    self.ref = [[FIRDatabase database] referenceFromURL: BASE_URL];
    
    self.handle = [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user)
    {
        NSLog(@"auth:%@, user:%@, currentUser:%@",auth,user, _currentUser);
    }];
}


-(void) viewWillAppear:(BOOL)animated
{
    // logout button tapped from GalleryCollectionViewController, reset input fields to NULL
    if (self.galleryVC.isLoggedOut) {
        // reset textfields and properties
        self.userEmail.text = @"";
        self.userPassword.text = @"";
        [self.logoutButton setHidden:YES];

    }
    else {
        self.userName.text = @"b";
        self.userEmail.text = @"b@b.com";
        self.userPassword.text = @"1234567";
    }

}

- (IBAction)loginButtonTapped:(UIButton *)sender
{
    // save user,email,password to nsuserdefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.userName.text forKey:@"user"];
    [defaults setObject:self.userEmail.text forKey:@"email"];
    [defaults setObject:self.userPassword.text forKey:@"password"];
    
    [defaults synchronize];
    
    if (![self.userEmail.text isEqualToString: @""] && ![self.userPassword.text isEqualToString: @""])
    {
        //email and password textfields are entered
        [[FIRAuth auth] signInWithEmail: self.userEmail.text password: self.userPassword.text completion:^(FIRUser *user, NSError *error) {
            if (error == nil)    
            {
                // signed success.
                NSLog(@"user account in database, login success %@", user.uid);
                NSLog(@"user account in database, login success %@",  [[FIRAuth auth]currentUser].uid );
            
                //  save uid to nsuserdefaults
                [defaults setObject:[[FIRAuth auth]currentUser].uid forKey:@"uid"];
                NSLog(@"userid:%@",[[FIRAuth auth]currentUser].uid);
            
                // perform segue to tab bar controller
                [self performSegueWithIdentifier:@"showTab" sender:self];
            }
            else
            {
                // error
                NSLog(@"error: %@",error);
                NSString *msg = [NSString stringWithFormat:@"%@ Enter valid email and password, and click login or 'create account.'", error.localizedDescription];
                [self showAlertTitle:@"Oops!" andMsg: msg];
            }
        }];
    }
    else
    {
        [self showAlertTitle:@"Oops!" andMsg: @"Enter valid email and a password of 6 characters minimum"];
    }
}



- (IBAction)createAccount:(UIButton *)sender
{
    // save user,email,password to nsuserdefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.userName.text forKey:@"user"];
    [defaults setObject:self.userEmail.text forKey:@"email"];
    [defaults setObject:self.userPassword.text forKey:@"password"];
    [defaults synchronize];
    
    if ([self.userEmail.text isEqualToString: @""] && [self.userPassword.text isEqualToString: @""])
    {
        // error no email or password entered
        [self showAlertTitle:@"Oops!" andMsg: @"Enter valid email and a password of 6 characters minimum"];
    }
    else {
        //create user account
        [[FIRAuth auth]  createUserWithEmail:  self.userEmail.text  password: self.userPassword.text completion:^(FIRUser *user, NSError *error)
         {
             if (error == nil) {
                 // no errors, user successfully authenticated
                
                 NSString *uuidString = user.uid;
                 NSLog(@"uuidString:%@ - %@", user.uid, uuidString);
                 // store user, uuid, email, & password in nsuserdefaults
                 [defaults setValue:uuidString forKey:@"uid"];

//                 [[NSUserDefaults standardUserDefaults] setValue:self.userName.text forKey:@"user"];
//                 [[NSUserDefaults standardUserDefaults] setValue:self.userEmail.text forKey:@"email"];
//                 [[NSUserDefaults standardUserDefaults] setValue:self.userPassword.text forKey:@"password"];
                 [self.logoutButton setHidden:NO];
                 
                 [DAO writeNewUserToFirebaseLookupUsersTable:self.userName.text andUUID:uuidString];
                 
                 // perform segue to tab bar controller
                 [self performSegueWithIdentifier:@"showTab" sender:self];
             }
             else
             {
                 //errors, print error
                 NSLog(@"%@", error);
                 [self showAlertTitle:@"Oops!" andMsg:error.localizedDescription];
             }
         }];
        [self.logoutButton setHidden:NO];
    }
}

-(void) checkErrorCode:(NSInteger)code {
    NSString *msg;
    
    switch (code) {
        case 17008:
            msg = @"Invalid Email";
            break;
        case 17011:
            msg = @"User Not Found. Create a new account.";
            break;
        case 17009:
            msg = @"Invalid or Wrong Password - must be 6 characters.";
            break;
        case 17007:
            msg = @"Email Already In Use";
            break;
        case 17025:
            msg = @"Credential Already In Use";
            break;
        default:
            msg = @"Try again. Enter valid email & password.";
            break;
    }
    [self showAlertTitle:@"Oops!" andMsg: msg];
    
// Firebase Login error codes handled in switch
//InvalidEmail: 6; 17008
//UserNotFound: 9; 17011
//- WrongPassword: 7; 17009
//- EmailAlreadyInUse: 5; 17007
//- CredentialAlreadyInUse: 19; 17025
//
//  error codes trapped in switch default
//    - AccountExistsWithDifferentCredential: 10; 17012
//    - NetworkError: 15; 17020
//    - UserDisabled: 3; 17005
//    - UserMismatch: 18; 17024
//    - WeakPassword: 20; 17026
//    - InternalError: 23; 17999
//    - InvalidAPIKey: 17; 17023
//    - KeychainError: 22; 17995
//    - NoSuchProvider: 13; 17016
//    - TooManyRequests: 8; 17010
//    - AppNotAuthorized: 21; 17028
//    - InvalidUserToken: 14; 17017
//    - UserTokenExpired: 16; 17021
//    - InvalidCredential: 2; 17004
//    - InvalidCustomToken: 0; 17000
//    - CustomTokenMismatch: 1; 17002
//    - OperationNotAllowed: 4; 17006
//    - RequiresRecentLogin: 11; 17014
//    - ProviderAlreadyLinked: 12; 17015
    
}

-(void) showAlertTitle: (NSString *)title andMsg:(NSString *) msg
{

    // set up alert with message

    // Initialize the controller for displaying the message
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle:@"Oops!" message: msg preferredStyle:UIAlertControllerStyleAlert];

    // Create an OK button and associate the nextStep block with it
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style: UIAlertActionStyleDefault handler:nil];

    // Add the button to the controller
    [alert addAction: okButton];

    // Display the alert controller
    [self presentViewController:alert animated:YES completion:nil];

}

- (IBAction)logoutButtonTapped:(UIButton *)sender {
    
    [self.logoutButton setHidden:YES];
    self.userName.text = @"";
    self.userEmail.text = @"";
    self.userPassword.text = @"";
    
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
