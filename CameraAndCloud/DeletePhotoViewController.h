//
//  DeletePhotoViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 2/27/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"
#import "PhotoDetailViewController.h"

@interface DeletePhotoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end
