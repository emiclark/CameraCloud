//
//  TakeAPhotoViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/5/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Firebase;
@import FirebaseStorage;

@interface TakeAPhotoViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *selectPhotoButton;

@property (nonatomic, retain) FIRDatabaseReference *ref;
@property (nonatomic, strong) FIRStorageReference  *storageRef;
@property (nonatomic, strong) UIImage  *uploadSelectedImage;
@property (nonatomic, strong) NSString *selectedPhotoFilename;
@property (nonatomic, strong) NSMutableArray *photosArray;


- (void) saveMetaDataToPhotoObject: (FIRStorageMetadata *)metaData;

@end

