//
//  LoginViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/22/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

#define myOrangeColor  colorWithRed:236/255 green:83/255 blue: 6/255 alpha:1


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dao = [DAO sharedInstance];
    self.galleryVC = [[GalleryCollectionViewController alloc] init];
    self.galleryVC.isLoggedOut = NO;

    self.createAccountButton.titleLabel.textColor = [UIColor myOrangeColor];
    [[self.createAccountButton layer] setBorderWidth: 1.0f];
    [[self.createAccountButton layer] setBorderColor: [UIColor myOrangeColor].CGColor];
    
    self.logoutButton.titleLabel.textColor = [UIColor myOrangeColor];
    [[self.logoutButton layer] setBorderWidth: 1.0f];
    [[self.logoutButton layer] setBorderColor: [UIColor myOrangeColor].CGColor];
    [[self.logoutButton layer] setCornerRadius: 4.0f];
        
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

#pragma mark login/logout methods

- (IBAction)createAccount:(UIButton *)sender
{
    // save user,email,password to nsuserdefaults
    [self saveLoginInfoToUserDefaults];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self.userEmail.text isEqualToString: @""] && [self.userPassword.text isEqualToString: @""])
    {
        // error no email or password entered
        [self showAlertTitle:@"Oops!" andMsg: @"Enter valid email and a password of 6 characters minimum"];
    }
    else {
        //create user account
        [[FIRAuth auth]  createUserWithEmail:  self.userEmail.text  password: self.userPassword.text completion:^(FIRUser *user, NSError *error)
         {
             if (error == nil)
             {
                 // user successfully authenticated
                 [self.logoutButton setHidden:NO];
                 NSString *uuidString = user.uid;
                 NSLog(@"uuidString:%@ - %@", user.uid, uuidString);
                 
                 // store user, uuid, email, & password in nsuserdefaults
                 [defaults setValue:uuidString forKey:@"uid"];
                 [defaults synchronize];
                 
                 [self.dao registerNewUser:self.userName.text andUUID:uuidString];
                 
                 // initialize app settings
                 [self.dao setupApp];
             
                 // make logout button visible
                 [self.logoutButton setHidden:NO];

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
    }
}

- (IBAction)loginButtonTapped:(UIButton *)sender
{
    // save user,email,password to nsuserdefaults
    [ self saveLoginInfoToUserDefaults];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![self.userEmail.text isEqualToString: @""] && ![self.userPassword.text isEqualToString: @""])
        {
        //email and password textfields are entered
        [[FIRAuth auth] signInWithEmail: self.userEmail.text password: self.userPassword.text completion:^(FIRUser *user, NSError *error)
        {
            if (error == nil)
            {
                // login success
                NSLog(@"user account in database, login success %@, %@", user.uid, [[FIRAuth auth]currentUser].uid );
                
                //  save uid to nsuserdefaults
                [defaults setObject:[[FIRAuth auth]currentUser].uid forKey:@"uid"];
                [defaults synchronize];
            
                // initialize app settings
                [self.dao setupApp];
                
                // perform segue to tab bar controller
                [self performSegueWithIdentifier:@"showTab" sender:self];
            }
            else
            {
                // login error
                NSLog(@"error: %@",error);
                NSString *msg = [NSString stringWithFormat:@"%@ Enter valid email and password, and click login or 'create account.'", error.localizedDescription];
                [self showAlertTitle:@"Oops!" andMsg: msg];
            }
        }];
    }
    else
    {
        // username and email and password fields left blank
        [self showAlertTitle:@"Oops!" andMsg: @"Enter valid email and a password of 6 characters minimum"];
    }
}

- (IBAction)logoutButtonTapped:(UIButton *)sender
{
    // logout user and reset fields in login screen
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


#pragma mark utility methods

- (void) saveLoginInfoToUserDefaults
{
    // save user,email,password using nsuserdefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.userName.text forKey:@"username"];
    [defaults setObject:self.userEmail.text forKey:@"email"];
    [defaults setObject:self.userPassword.text forKey:@"password"];
    [defaults synchronize];
}


-(void) showAlertTitle: (NSString *)alertTitle andMsg:(NSString *) msg
{
    // show alert box with title and message
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle:alertTitle message: msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style: UIAlertActionStyleDefault handler:nil];
    [alert addAction: okButton];
    [self presentViewController:alert animated:YES completion:nil];
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
