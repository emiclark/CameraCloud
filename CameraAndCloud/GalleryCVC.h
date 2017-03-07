//
//  GalleryCVC.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/9/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Firebase;
@import FirebaseStorage;

@interface GalleryCVC : UICollectionViewController

@property (nonatomic, strong) NSString  *documentsDirectoryPath;
@property (nonatomic, strong) FIRStorageReference  *storageRef;
@property (nonatomic, strong) FIRStorageReference  *photoRef;
@property (nonatomic, weak) NSURLSession *session;

@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, weak) UICollectionViewCell *cell;

- (BOOL) checkIfPhotoInDocumentsDirectory;
- (void) downloadPhoto :(void (^)(void))completionBlock;
@end
