//
//  TakePhotoViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/23/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "AFNetworking.h"
#import "DAO.h"
#import "ImageInfo.h"
#import "GalleryCollectionViewController.h"

@import Firebase;
@import FirebaseStorage;
@import FirebaseDatabase;


@interface TakePhotoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate >

@property (strong, nonatomic) DAO *dao;
@property (nonatomic) BOOL isLoggedOut;
@property (strong, nonatomic) ImageInfo *imgInfo;
@property (retain, nonatomic) GalleryCollectionViewController *galleryVC;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (strong, nonatomic) UIImage  *selectedImage;

- (void) showAlertTitle:(NSDictionary *)alertInfo;
- (void)receivedNotification:(NSNotification *) notification;

@end
