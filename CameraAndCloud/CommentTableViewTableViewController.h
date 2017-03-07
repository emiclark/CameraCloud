//
//  CommentTableViewTableViewController.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 3/4/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAO.h"

@interface CommentTableViewTableViewController : UITableViewController
@property (nonatomic, retain) DAO *dao;
@property (weak, nonatomic) IBOutlet UILabel *user;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end
