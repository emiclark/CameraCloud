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
@property (retain, nonatomic) GalleryCollectionViewController *galleryVC;

@property (strong, nonatomic) ImageInfo *imgInfo;
@property (strong, nonatomic) UIImage  *selectedImage;
@property (nonatomic) BOOL isLoggedOut;

@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

- (void)receivedNotification:(NSNotification *) notification;

@end
