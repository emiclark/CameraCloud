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

@class GalleryCollectionViewController;


@import Firebase;
@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;


@interface DAO : NSObject

@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (strong, nonatomic) FIRStorageReference *imageRef;
@property (strong, nonatomic) FIRDatabaseReference *dbRef;

@property (retain, nonatomic) NSMutableArray <ImageInfo*> *imagesArray;
@property (retain, nonatomic) NSMutableArray <Comment*> *commentArray;
@property (strong, nonatomic) NSArray *fileList;

@property (strong, nonatomic) Photo *photoDataForUser;
@property (nonatomic) BOOL finishedDownloadingImages;

@property (strong, nonatomic) UIImage  *selectedImage;
@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSString *fileDate;
@property (strong, nonatomic) NSString *DDpath;


+ (id)sharedInstance;
- (void) setupApp;
- (void) addPhotosInDDToImagesArray;
- (void) addDownloadedPhotosToImagesArray:(NSDictionary*)responseData;

- (void) downloadCloudDataForAllPhotos;
- (void) downloadPhotoWithFilename: (ImageInfo *) info;
- (void) downloadDataForSelectedPhoto:(ImageInfo *)info;

- (ImageInfo*) uploadNewPhoto:(UIImage *)selectedImage withImageInfo: (ImageInfo*)info;
- (void) updateDataForSelectedPhoto:(Photo *) info;

- (void) registerNewUser:(NSString*) user andUUID:(NSString*) uuidString;
- (void) registerFilenameForNewPhoto: (ImageInfo *) info;
- (void) writeDataForNewPhoto: (ImageInfo *) info;

- (void) deletePhotoAndData:(Photo*)photoInfo;

- (void) getDocumentDirectoryPath;
- (void) saveImageToDD: (UIImage*) image ToDDirectoryWithFilename:(NSString *)filename;
- (void) updateImagesArrayForAllDownloadedPhotos:(NSDictionary *) responseData;
- (void) updateImagesArrayWithDownloadedData:(ImageInfo *)info;
- (NSString *) createFilename;
- (UIImage *) resizeImage:(UIImage *)image;
+ (void) printImagesArray: (NSMutableArray *)array;


@end
