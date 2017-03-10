//
//  DAO.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/30/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "Photo.h"
#import "ImageInfo.h"
#import "Comment.h"
#import "PhotoDetailViewController.h"

@class GalleryCollectionViewController;


@import Firebase;
@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;


@interface DAO : NSObject

@property (retain, nonatomic) NSMutableArray <ImageInfo*> *imagesArray;
@property (retain, nonatomic) NSMutableArray <Comment*> *commentArray;
@property (retain, nonatomic) NSString *imagesArrayPath;

@property (strong, nonatomic) UIImage  *selectedImage;
@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSString *fileDate;
@property (strong, nonatomic) NSString *DDpath;

@property (strong, nonatomic) Photo *photoDataForUser;
@property (nonatomic) BOOL finishedDownloadingImages;


@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (strong, nonatomic) FIRStorageReference *imageRef;
@property (strong, nonatomic) FIRDatabaseReference *dbRef;

+ (id)sharedInstance;

- (void) doWhenAppLaunches;
- (void) downloadCloudDataForPhotos: (NSArray *) fileList;
- (void) downloadPhotoWithFilename: (ImageInfo *) info;
- (void) downloadDataForSelectedPhotoFromFirebaseUsersTable:(ImageInfo *)info;

- (UIImage *)resizeImage:(UIImage *)image;
- (ImageInfo*) uploadImageToFirebase:(UIImage *)selectedImage withImageInfo: (ImageInfo*)info;
- (void) writeToFireBaseLookupUsersTable: (ImageInfo *) info;
- (void) writeUserDataToFirebaseUsersTable: (ImageInfo *) info;
+ (void) writeNewUserToFirebaseLookupUsersTable:(NSString*) user andUUID:(NSString*) uuidString;
+ (void) updateDataForSelectedPhotoToFirebaseUsersTable:(Photo *) info;

- (FIRStorageReference *) setFirebaseStorageReferences;
- (FIRDatabaseReference *) setFirebaseDBReferences;
- (void) getDocumentDirectoryPath;
- (NSString *) createFilename;
- (void) saveImage: (UIImage*) image ToDDirectoryWithFilename:(NSString *)filename;
+ (void) printImagesArray: (NSMutableArray *)array;
- (void) updateImagesArrayWithInfo:(ImageInfo *)info;

@end
