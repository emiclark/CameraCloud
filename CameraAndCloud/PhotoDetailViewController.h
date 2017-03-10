//
//  PhotoDetailViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/26/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "ImageInfo.h"
#import "Photo.h"
#import "DAO.h"

@import Firebase;
@import FirebaseDatabase;

@interface PhotoDetailViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>


@property (retain, nonatomic)  Photo *photoInfo;
@property (strong, nonatomic) ImageInfo *info;
@property BOOL photoDataChanged;
@property (strong, nonatomic) IBOutlet UIImageView *img;
@property (strong, nonatomic) IBOutlet UILabel *likesLabel;

@property (weak, nonatomic) IBOutlet UIButton *deletePhotoButton;

@property (strong, nonatomic) IBOutlet UIButton *commentButton;
@property (strong, nonatomic) IBOutlet UIButton *likesButton;
@property (strong, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UIView *commentView;
@property (weak, nonatomic) IBOutlet UITextView *commentTextBox;

@property (weak, nonatomic) IBOutlet UIButton *commentDoneButton;


- (IBAction)deletePhotoButtonTapped:(UIButton *)sender;
- (void) showDeletePhotoAlert:(NSDictionary *) alertInfo;

@end
