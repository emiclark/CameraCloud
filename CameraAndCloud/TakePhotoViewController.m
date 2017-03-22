//
//  TakePhotoViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/23/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "TakePhotoViewController.h"

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

-(void)viewWillAppear:(BOOL)animated{
    
}

#pragma mark Button Tapped Methods

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


#pragma mark picker methods

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    self.selectedImage = info[UIImagePickerControllerOriginalImage];
    
    // resize image before uploading to Firebase
    self.selectedImage = [self.dao resizeImage:self.selectedImage];
    
    // prepare to upload image to Firebase storage
    
    // create info object and save to imagesArray
    ImageInfo *imgInfo =  [[ImageInfo alloc]init];
    imgInfo.filename = [self.dao createFilename];
    imgInfo.indexInImagesArray = 0;
    imgInfo.imageDDPath = [NSString stringWithFormat:@"%@/%@.jpg", self.dao.DDpath, imgInfo.filename];
    imgInfo.username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    imgInfo.downloadURL = @"";
    
    // save image to DDirectory
    [self.dao saveImageToDD:self.selectedImage ToDDirectoryWithFilename: imgInfo.imageDDPath];
    
    // upload selected image to Firebase
    imgInfo = [self.dao uploadNewPhoto: self.selectedImage withImageInfo: imgInfo];
    
    // add image info to imagesArray
    [self.dao.imagesArray addObject: imgInfo];
    
    // notify update to refresh collection view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
    
    //dismiss imagepicker
    [self dismissViewControllerAnimated:picker completion:^{
        NSLog(@"picker dismissed");
    }];

}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:picker completion:nil];
}


#pragma mark utility/alert Methods


-(void)receivedNotification:(NSNotification *) notification
{
    NSLog(@"Second View Notification Received: %@", [notification name]);
    
    NSDictionary *alertInfo = [notification userInfo];
    
    self.alert = [UIAlertController alertControllerWithTitle: [alertInfo objectForKey:@"alertTitle"] message: [alertInfo objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                            NSLog(@"ddsfs");
                            //Do some thing here
                            //[view dismissViewControllerAnimated:YES completion:nil];
                         
                         }];
    [self.alert addAction:ok];
    [self presentViewController:self.alert animated:YES completion:nil];

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
