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
    self.dao = [DAO sharedInstance];
    self.img.image = [UIImage imageNamed:  self.photoInfo.DDfilePath];
    self.likesLabel.text = [NSString stringWithFormat:@"%@ likes", self.photoInfo.likes];
    self.photoDataChanged = NO;
    [self.commentView setHidden:YES];
    self.isDelete = NO;
    
    // show like button ON or OFF depending on if user liked photo
    self.userDidLikePhoto = [self.dao checkIfUserLikedPhoto: self.photoInfo];
    if (self.userDidLikePhoto)
        {
        //show liked button-ON
        [self.likesButton setSelected:YES];
        [self.likesButton setBackgroundImage:[UIImage imageNamed: @"button-heart-ON.jpg"] forState:UIControlStateNormal];
        }
    else
        {
        //show liked button-OFF
        [self.likesButton setSelected:NO];
        [self.likesButton setBackgroundImage:[UIImage imageNamed:@"button-heart-OFF.jpg"] forState: UIControlStateNormal];
        }
}





-(void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound && !self.isDelete)
        {
        // Firebase update here
        [self.dao updateDataForSelectedPhoto: self.photoInfo];
        
        [self.navigationController popViewControllerAnimated:NO];
        }
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - buttons tapped methods

- (IBAction)likeButtonTapped:(UIButton *)sender
{
    NSLog(@"like button tapped");
    self.photoDataChanged = YES;
    int likes = [self.likesLabel.text intValue];
    
    NSString *currentUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    
    if (self.userDidLikePhoto)
        {
        // user clicked to unlike photo
        self.userDidLikePhoto = NO;
        [self toggleUIButtonImage:self.likesButton];
        self.likesLabel.text = [NSString stringWithFormat:@"%d likes", likes-1];
        self.photoInfo.likes = [NSNumber numberWithInt: likes-1];
        
        // remove user from likesArray
        [self.photoInfo.likesArray removeObject: currentUser];
        }
    else
        {
        // user clicked to like photo
        self.userDidLikePhoto = YES;
        
        // show liked button-ON
        [self toggleUIButtonImage:self.likesButton];
        self.likesLabel.text = [NSString stringWithFormat:@"%d likes", likes+1];
        self.photoInfo.likes = [NSNumber numberWithInt: likes+1];
        
        [self.photoInfo.likesArray addObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"username"]];
        
        }
}

-(IBAction) toggleUIButtonImage:(id)sender
{
    if ([sender isSelected]) {
        [sender setBackgroundImage:[UIImage imageNamed: @"button-heart-OFF.jpg"] forState:UIControlStateNormal];
        [sender setSelected:NO];
    } else {
        [sender setBackgroundImage:[UIImage imageNamed: @"button-heart-ON.jpg"] forState:UIControlStateSelected];
        [sender setSelected:YES];
    }
}


- (IBAction)commentButtonTapped:(UIButton *)sender
{
    self.commentTextBox.text = @"";
    [self.commentTableView setHidden:NO];
    [self.commentView setHidden:NO];
    self.photoDataChanged = YES;
}

- (IBAction)commentSaveButtonTapped:(UIButton *)sender
{
    NSLog(@"comment Done button tapped");
    Comment *newComment = [[Comment alloc] initWithUsername:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"] andText:self.commentTextBox.text];
    
    [[self.photoInfo valueForKey:@"commentsArr" ] insertObject: newComment atIndex:0];
    
    [self.commentView setHidden:YES];
    [self.commentTableView setHidden:NO];
    [self.commentTableView reloadData];
    [self.view endEditing:YES];
}

- (IBAction)commentCancelButtonTapped:(UIButton *)sender
{
    [self.view endEditing:YES];
    [self.commentView setHidden:YES];
    [self.commentTableView setHidden:NO];
}


- (IBAction)deletePhotoButtonTapped:(UIButton *)sender
{
    NSLog(@"delete photo button tapped");
    self.isDelete = YES;
    self.photoDataChanged = YES;
    
    [self deletePhoto];
}

- (void) deletePhoto
{
    // Initialize the alert box controller for displaying "delete photo" message
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle: @"Delete Photo" message: @"Are you sure you want to delete this photo?" preferredStyle:UIAlertControllerStyleAlert];
    
    // Create buttons
    UIAlertAction *deleteButton = [UIAlertAction actionWithTitle:@"Delete" style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action) {
        
        // delete photo from Documents Directory
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:self.photoInfo.DDfilePath error:&error];
        if (success) {
            NSLog(@"success - photo deleted from DD");
        }
        else
            {
            NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
            }
        
        // remove photo from imagesArray
        [self.dao.imagesArray removeObjectAtIndex: self.photoInfo.indexInImagesArray];
        
        // remove photo from Firebase
        [self.dao deletePhotoAndData: self.photoInfo];
        
        // send notification to update collection view
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object: nil userInfo: nil];
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    // Add the button to the controller
    [alert addAction: deleteButton];
    [alert addAction: cancelButton];
    
    // Display the alert controller
    [self presentViewController: alert animated:YES completion:nil];
    
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.photoInfo.commentsArr.count == 0)
        {
            // if no comments, return 1 row to display "Be the first to comment!"
            return 1;
        } else
            return self.photoInfo.commentsArr.count;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    self.commentTableView.rowHeight = UITableViewAutomaticDimension;
    self.commentTableView.estimatedRowHeight = 120;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableString *str;
    if (self.photoInfo.commentsArr.count > 0)
        {
        // there are more than one comments
        str = (NSMutableString*)[NSString stringWithFormat:@"  %@:  %@",[[self.photoInfo.commentsArr objectAtIndex:indexPath.row] username], [[self.photoInfo.commentsArr objectAtIndex:indexPath.row] text] ];
        } else {
            str = (NSMutableString*)@"   Be the first to comment!";
        }
    
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
