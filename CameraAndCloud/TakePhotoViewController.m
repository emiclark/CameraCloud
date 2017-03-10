//
//  TakePhotoViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/23/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "TakePhotoViewController.h"

NSString *email;
NSString *username;

@interface TakePhotoViewController ()
@end

@implementation TakePhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dao = [DAO sharedInstance];

    // listen for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification:) name:@"showAlert" object:nil];
}

#pragma mark Button Tapped Methods


//
- (IBAction)takePhotoButtonTapped:(UIButton *)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


- (IBAction)uploadPhotoButtonTapped:(UIButton *)sender
{
    NSLog(@"Upload Photo");
    // go to photo gallery on iPhone
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController: picker animated:YES completion:nil ];
}

- (IBAction)logoutButtonTapped:(UIButton *)sender {
    self.isLoggedOut = YES;
    
    // sign out
    NSError *signOutError;
    
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    
    // dismiss tabViewController and go back to login screen to logout
    [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
}


// gallery
-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    self.selectedImage = info[UIImagePickerControllerOriginalImage];
    
    // resize image before uploading to Firebase
    self.selectedImage = [[DAO sharedInstance] resizeImage:self.selectedImage];

    // prepare to upload image to Firebase storage
    
    // create info object and save to imagesArray
    ImageInfo *imgInfo =  [[ImageInfo alloc]init];
    imgInfo.filename = [self.dao createFilename];
    imgInfo.imageDDPath = [NSString stringWithFormat:@"%@/%@.jpg", self.dao.DDpath, imgInfo.filename];
    imgInfo.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    imgInfo.downloadURL = @"";
    
    // save image to DDirectory
    [self.dao saveImage:self.selectedImage ToDDirectoryWithFilename: imgInfo.imageDDPath];
    
    NSLog(@"imagePickerController: imgInfo: %@",imgInfo);
    
    // upload selected image to Firebase
    imgInfo = [self.dao uploadImageToFirebase: self.selectedImage withImageInfo: imgInfo];
    
    // add image info to imagesArray
    [self.dao.imagesArray addObject: imgInfo];

    // notify update to refresh collection view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
    
    //dismiss imagepicker
    [self dismissViewControllerAnimated:picker completion:nil];
    
    
}

#pragma mark Alert and Notification Methods


-(void)receivedNotification:(NSNotification *) notification
{
    NSLog(@"Second View Notification Received: %@", [notification name]);
    
    NSDictionary *alertInfo = [notification userInfo];
    [self showAlertTitle: alertInfo];
}

#pragma  mark Utility Methods

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:picker completion:nil];
}


- (void) showAlertTitle:(NSDictionary *) alertInfo
{
    // pop up alert -  error

    // Initialize the controller for displaying the message
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle: [alertInfo objectForKey:@"alertTitle"] message: [alertInfo objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];

    // Create an OK button and associate the nextStep block with it
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style: UIAlertActionStyleDefault handler:nil];

    // Add the button to the controller
    [alert addAction: okButton];

    // Display the alert controller
    [self presentViewController: alert animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
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
