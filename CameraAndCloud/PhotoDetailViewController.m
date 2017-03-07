//
//  PhotoDetailViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/26/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "PhotoDetailViewController.h"

@interface PhotoDetailViewController () 

@end

@implementation PhotoDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.img.image = [UIImage imageNamed:  self.photoInfo.DDfilePath];
    self.likesLabel.text = [NSString stringWithFormat:@"%@ likes", self.photoInfo.likes];    
    self.photoDataChanged = NO;
}


-(void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound)
        {
        
            // Firebase update here
            [DAO updateDataForSelectedPhotoToFirebaseUsersTable: self.photoInfo];
        
            // Navigation button was pressed. Do some stuff
            [self.navigationController popViewControllerAnimated:NO];
        }
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)likeButtonTapped:(UIButton *)sender {
    NSLog(@"like button tapped");
    self.photoDataChanged = YES;
    int likes = [self.likesLabel.text intValue];
    [self.likesButton setBackgroundImage:[UIImage imageNamed:@"button-heart-ON.jpg"] forState: UIControlStateHighlighted];
    self.likesLabel.text = [NSString stringWithFormat:@"%d likes", likes+1];
    self.photoInfo.likes = [NSNumber numberWithInt: likes+1];
}

- (IBAction)moreButtonTapped:(UIButton *)sender {
    NSLog(@"more button tapped");
    self.photoDataChanged = YES;
    DeletePhotoViewController *deletePhotoVC = [[DeletePhotoViewController alloc]init];
    [self.navigationController pushViewController:deletePhotoVC animated:YES];
}

- (IBAction)commentButtonTapped:(UIButton *)sender {
    NSLog(@"comment button tapped");
    Comment *newComment = [[Comment alloc] initWithUsername:@"emi" andText:@"this is a test"];
    [self.photoInfo.commentsArr addObject:newComment];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.photoInfo.commentsArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
   
    NSString *str = [NSString stringWithFormat:@"  %@:  %@",[[self.photoInfo.commentsArr objectAtIndex:indexPath.row] username], [[self.photoInfo.commentsArr objectAtIndex:indexPath.row] text] ];
    cell.textLabel.text = str;
    
    return cell;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
