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
    [self.commentView setHidden:YES];
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

- (IBAction)deletePhotoButtonTapped:(UIButton *)sender
{
    NSLog(@"delete photo button tapped");
    self.photoDataChanged = YES;
    //create alertbox
    NSDictionary *alert = [[NSDictionary alloc] initWithObjectsAndKeys: @"Delete Photo", @"alertTitle", @"Are you sure you want to delete photo?", @"msg",  nil];
    [self showDeletePhotoAlert :alert];
    
}

- (void) showDeletePhotoAlert:(NSDictionary *) alertInfo
{
    // pop up alert
    // Initialize the controller for displaying the message
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle: [alertInfo objectForKey:@"alertTitle"] message: [alertInfo objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
    
    // Create buttons
    UIAlertAction *deleteButton = [UIAlertAction actionWithTitle:@"Delete" style: UIAlertActionStyleDefault handler:nil];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style: UIAlertActionStyleDefault handler:nil];
    
    // Add the button to the controller
    [alert addAction: deleteButton];
    [alert addAction: cancelButton];
    
    // Display the alert controller
    [self presentViewController: alert animated:YES completion:nil];
}




- (IBAction)commentButtonTapped:(UIButton *)sender {
    NSLog(@"comment button tapped");
    [self.commentTableView setHidden:YES];
    [self.commentView setHidden:NO];
    self.photoDataChanged = YES;
}

- (IBAction)commentDoneButtonTapped:(UIButton *)sender {
    NSLog(@"comment Done button tapped");
    Comment *newComment = [[Comment alloc] initWithUsername:[[NSUserDefaults standardUserDefaults] valueForKey:@"username"] andText:self.commentTextBox.text];
    
    [[self.photoInfo valueForKey:@"commentsArr" ] insertObject: newComment atIndex:0];
    
    [self.commentView setHidden:YES];
    [self.commentTableView setHidden:NO];
    [self.commentTableView reloadData];
    [self.view endEditing:YES];
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
   
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSMutableString *str;
    if (self.photoInfo.commentsArr.count == 0 && [self.photoInfo.commentsArr isEqual: @"" ])
    {
        //set placeholder text
        str = (NSMutableString*)@"  Be the first to comment!";
    }
    else if (self.photoInfo.commentsArr.count > 0)
    {
        // there are more than one comments
        str = (NSMutableString*)[NSString stringWithFormat:@"  %@:  %@",[[self.photoInfo.commentsArr objectAtIndex:indexPath.row] username], [[self.photoInfo.commentsArr objectAtIndex:indexPath.row] text] ];
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
