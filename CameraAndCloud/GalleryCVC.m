//
//  GalleryCVC.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/9/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "GalleryCVC.h"
#import "PhotoCollectionViewCell.h"

@interface GalleryCVC ()

@end

@implementation GalleryCVC

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photo = [[UIImage alloc] init];
    
    // find path to documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    self.documentsDirectoryPath = [paths objectAtIndex:0];
    
    // get root storage reference for Firebase Storage/images folder
    self.storageRef = [[FIRStorage storage] referenceForURL: @"gs://cameraandcloud-935e4.appspot.com"];
    
    // Create a reference to the file you want to download
    self.photoRef = [self.storageRef child:@"images/file.jpg"];

//=================
    //----- LIST ALL FILES  IN DOCUMENTS DIRECTORY -----
    NSLog(@"LISTING ALL FILES FOUND");
    
    int count;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: self.documentsDirectoryPath error: NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
//=================
    
}

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
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    //check if file is in documents directory
    BOOL photoExists = [self checkIfPhotoInDocumentsDirectory];
    
    if (photoExists) {
        NSLog(@"photo exists");
        // photo exists in documents directory
        cell.photo.image = self.photo;
    }
    else {
        // download photo
        NSLog(@"photo does NOT exist");
        [self downloadPhoto:^{
            // call update to UI on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.photo.image = self.photo;
            });
            
        }];
        
    }
    
//    if (!photoExists) {
//        //download photo
//        [self downloadPhoto];
//    }
//    cell.photo.image = self.photo;
    
    return cell;


}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark NSURLSession Delegate Methods

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // shows download progress
    CGFloat percentDone = (double)totalBytesWritten/(double)totalBytesExpectedToWrite;
    // Notify user.
    NSLog(@"%f Percent done.", percentDone);
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // save downloaded photo from Firebase storage
    NSData *downloadedImageData = [NSData dataWithContentsOfURL:location];
    
    //save photo to documents directory
    if (downloadedImageData != nil) {
        // create path to save photo
        NSString *path = [self.documentsDirectoryPath stringByAppendingPathComponent:@"file.jpg"];
        
        // save photo to documents directory
        [downloadedImageData writeToFile:path atomically:YES];
        NSLog(@"Download success: %@",path);
    }
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}



#pragma mark Misc Download/Save Methods

- (BOOL) checkIfPhotoInDocumentsDirectory  {
    
    NSString* path = [self.documentsDirectoryPath stringByAppendingPathComponent:@"file.jpg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])  {
        
        // photo exists in document directory, return image
        NSData *retrievedData = [NSData dataWithContentsOfFile:path];
        self.photo = [UIImage imageWithData:retrievedData];
        
//        self.photo = [UIImage imageWithContentsOfFile:path];
        return YES;
    }
    return NO;
}

//- (void) downloadPhoto completion:(void (^)(void))completionBlock  {
//    
//    if (successful) {
//        completionBlock();
//    }
//    
//    // download photo from Firebase Storage
//    
//    // Create Firebase Storage URL
//    
//    // path of photo in Firebase
//    NSString *path = @"https://firebasestorage.googleapis.com/v0/b/cameraandcloud-935e4.appspot.com/o/images%2Ffile.jpg?alt=media&token=a85c35f5-04af-43a8-98b1-dd2f3caf016a";
//    
//    // convert NSString to NSURLRequest
//    NSURL *url = [NSURL URLWithString: path];
//    
//    // create nsurlsession configuration
//    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration  defaultSessionConfiguration];
//    
//    // create nsurlsession
//    NSURLSession *session = [NSURLSession sessionWithConfiguration: sessionConfig];
//    
//    // create download task
//    NSURLSessionDownloadTask *downloadPhotoTask = [session  downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
//        
//        NSLog(@"l:%@ \nr:%@, \ne:%@\n\n", location, response, error);
//        
//        NSData *data = [NSData dataWithContentsOfURL:location];
//        // save photo to documents directory
//        // create path to save photo
//        NSString *path = [self.documentsDirectoryPath stringByAppendingPathComponent:@"file.jpg"];
//        
//        self.photo = [UIImage imageWithData:data];
//        // save photo to documents directory
//        [data writeToFile:path atomically:YES];
//        NSLog(@"Download success: %@",path);
//        
//        
//    }];
//    
//    // fire download request
//    [downloadPhotoTask resume];
//    
//   
//}

- (void) downloadPhoto :(void (^)(void))completionBlock  {
    
    // Method downloads a photo from Firebase Storage
    // Create Firebase Storage URL - path of test photo in Firebase
    NSString *path = @"https://firebasestorage.googleapis.com/v0/b/cameraandcloud-935e4.appspot.com/o/images%2Ffile.jpg?alt=media&token=a85c35f5-04af-43a8-98b1-dd2f3caf016a";
    
    // convert NSString to NSURLRequest
    NSURL *url = [NSURL URLWithString: path];
    
    // create nsurlsession configuration
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration  defaultSessionConfiguration];
    
    // create nsurlsession
    NSURLSession *session = [NSURLSession sessionWithConfiguration: sessionConfig];
    
    // create download task
    NSURLSessionDownloadTask *downloadPhotoTask = [session  downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        NSLog(@"l:%@ \nr:%@, \ne:%@\n\n", location, response, error);
        
        NSData *data = [NSData dataWithContentsOfURL:location];
        // save photo to documents directory
        // create path to save photo
        NSString *path = [self.documentsDirectoryPath stringByAppendingPathComponent:@"file.jpg"];
        
        self.photo = [UIImage imageWithData:data];
        completionBlock();

        
        // save photo to documents directory
        [data writeToFile:path atomically:YES];
        NSLog(@"Download success: %@",path);
        
        
    }];
    
    // fire download request
    [downloadPhotoTask resume];
    
    
}


@end
