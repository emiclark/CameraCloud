//
//  PhotoDetailViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/26/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "DeletePhotoViewController.h"
#import "ImageInfo.h"
#import "Photo.h"
#import "DAO.h"

@import Firebase;
@import FirebaseDatabase;

@interface PhotoDetailViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>


@property (retain, nonatomic)  Photo *photoInfo;
@property (strong, nonatomic) ImageInfo *info;
@property BOOL photoDataChanged;

@property (retain, nonatomic) NSArray *commentsArr;

@property (strong, nonatomic) IBOutlet UIImageView *img;
@property (strong, nonatomic) IBOutlet UILabel *likesLabel;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;
@property (strong, nonatomic) IBOutlet UIButton *likesButton;
@property (strong, nonatomic) IBOutlet UITableView *commentTableView;



@end
