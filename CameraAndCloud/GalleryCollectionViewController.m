//
//  GalleryCollectionViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/23/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "LoginViewController.h"
#import "Photo.h"

@import FirebaseAuth;


@interface GalleryCollectionViewController ()
@end

@implementation GalleryCollectionViewController

static NSString * const reuseIdentifier = @"Cell";
UIBarButtonItem *logoutButton;
UIActivityIndicatorView *activityView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dao = [DAO sharedInstance];
    
    // listen for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotificationForAlertBox:) name:@"showAlert" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotificationForUpdate:) name:@"Update" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotificationForSegue:) name:@"Segue" object:nil];
    
    // add back to login page button
    logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"logout" style:UIBarButtonItemStylePlain target:self action: @selector(logoutButtonTapped:)];
    
    self.navigationItem.leftBarButtonItem = logoutButton;
    
    // Uncomment the following line to preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = YES;
    
    // add activityIndicator
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.color = [UIColor orangeColor];
    activityView.center=self.view.center;
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:activityView];
}

- (void) viewWillAppear:(BOOL)animated
{
    if (!self.dao.finishedDownloadingImages)
        [activityView startAnimating];
    else [activityView stopAnimating];
}


#pragma mark Alert and Notification Methods

- (void)receivedNotificationForAlertBox:(NSNotification *)notification
{
    // show alert box with message
    NSLog(@"Notification Received: %@", [notification name]);
    
    NSDictionary *alertInfo = [notification userInfo];
    
    // Initialize the controller for displaying the message
    UIAlertController  *alert = [UIAlertController alertControllerWithTitle: [alertInfo objectForKey:@"alertTitle"] message: [alertInfo objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
    
    // Create an OK button and associate the nextStep block with it
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style: UIAlertActionStyleDefault handler:nil];
    
    // Add the button to the controller
    [alert addAction: okButton];
    [activityView stopAnimating];
    
    // Display the alert controller
    [self presentViewController: alert animated:YES completion:nil];
}


- (void)receiveNotificationForUpdate:(NSNotification *)notification
{
    // update collection view
    [activityView stopAnimating];
    [self.collectionView reloadData];
}

- (void)receiveNotificationForSegue:(NSNotification *)notification
{
    // perform segue to detailsVC
    UIStoryboard *main = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    PhotoDetailViewController *detailVC = [main instantiateViewControllerWithIdentifier:@"photoDetail"];
    detailVC.photoInfo = self.dao.photoDataForUser;
    
    [self.navigationController pushViewController:detailVC animated:YES];
}



#pragma mark Alert and Notification Methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dao.imagesArray.count;
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.photo.image = [UIImage imageWithContentsOfFile: [[self.dao.imagesArray objectAtIndex:indexPath.row] imageDDPath]];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.info = [[ImageInfo alloc] init];
    self.info = [self.dao.imagesArray objectAtIndex: indexPath.row];
    self.info.indexInImagesArray = (int)indexPath.row;
    
    [self.dao downloadDataForSelectedPhoto: self.info];
}

// Uncomment this method to specify if the specified item should be selected
// - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
// return YES;
// }

#pragma mark logout method

- (IBAction)logoutButtonTapped:(UIBarButtonItem *)sender {
    
    self.isLoggedOut = YES;
    
    // sign out
    NSError *signOutError;
    
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    
    // dismiss tabViewController and go back to login screen to logout
    [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
}

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
 }
 */


/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
 }
 
 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
 }
 */

@end
