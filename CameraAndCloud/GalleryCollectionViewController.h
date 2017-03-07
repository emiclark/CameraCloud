//
//  GalleryCollectionViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/23/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoCollectionViewCell.h"
#import "PhotoDetailViewController.h"
#import "Photo.h"
#import "imageInfo.h"
#import "DAO.h"




@import Firebase;

@interface GalleryCollectionViewController : UICollectionViewController

@property (nonatomic) BOOL isLoggedOut;
@property (nonatomic, retain) DAO *dao;
@property (nonatomic, strong) FIRDatabaseReference *ref;
@property (nonatomic, strong) FIRStorageReference *imagesRef;
@property (nonatomic, strong) Photo *photoInfo;
@property (nonatomic, strong) ImageInfo *info;

//@property (nonatomic, strong) PhotoCollectionViewCell  *cells;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *logoutButton;
@property (nonatomic, strong) IBOutlet UICollectionView *galleryCV;

- (IBAction)logoutButtonTapped:(UIBarButtonItem *)sender;
- (void)receivedNotificationForAlertBox:(NSNotification *)notification;
- (void)receiveNotification:(NSNotification *)notification;
- (void)receiveNotificationForSegue:(NSNotification *)notification;

@end
