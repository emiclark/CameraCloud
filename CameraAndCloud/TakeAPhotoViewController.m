//
//  TakeAPhotoViewController.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/5/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "TakeAPhotoViewController.h"
#import "Photo.h"
#import "AFNetworking.h"

@interface TakeAPhotoViewController ()

@end

@implementation TakeAPhotoViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ref = [[FIRDatabase database] reference];
    
}

- (IBAction)TakePhotoButtonTapped:(UIButton *)sender {
    NSLog(@"TakePhotoButtonTapped");
    
}

- (IBAction)SelectPhotoButtonTapped:(UIButton *)sender {
    NSLog(@"UploadPhotoButtonTapped");
    
    // go to photo gallery on iPhone
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController: picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    self.uploadSelectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];

    // Points to the root reference
    self.storageRef = [[FIRStorage storage] referenceForURL: @"gs://cameraandcloud-935e4.appspot.com"];
    
    // get uinique ID for each image filename to upload to storage
    NSString *UUID = [[NSUUID UUID] UUIDString];
                          
    NSData *selectedImageData = UIImageJPEGRepresentation(self.uploadSelectedImage, 0.8);
    FIRStorageMetadata *metaData = [[FIRStorageMetadata alloc]init];
    metaData.contentType = @"image/jpeg";
    
    // UPLOAD from Firebase
    FIRStorageReference *imageRef = [[self.storageRef child:@"images"]child:UUID];
    
    [imageRef putData: selectedImageData metadata: metaData completion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error != nil) {
            //  Uh-oh, an error occurred!
            
            // create alert box that the file uploaded has Failed
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle:@"Photo Upload"
                                          message:@"Failed!"
                                          preferredStyle:UIAlertControllerStyleAlert];

            [self presentViewController:alert animated:YES completion:nil];

            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                 [self dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:ok]; // add action to uialertcontroller
            
            
        } else {
            // create alert box that file was uploaded successfully
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle:@"Photo Upload"
                                          message:@"Successful!"
                                          preferredStyle:UIAlertControllerStyleAlert];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                 [self dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [alert addAction:ok]; // add action to uialertcontroller
            
            
            
            NSURL *downloadURL = metadata.downloadURL;
            NSString *userID = @"emiClark2";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MMddyyHHmmss"];
            NSString *fileDate = [dateFormatter stringFromDate:[NSDate date]];
            NSString *filename = [NSString stringWithFormat: @"%@.jpg", fileDate];
            NSLog(@"\nfilename:%@",filename);
            
            // create temp comments array
            NSMutableArray *comments = [[NSMutableArray alloc] init];
            [comments addObject:@"one"];
            [comments addObject:@"two"];
            [comments addObject:@"three"];
            
            NSDictionary *photoDataToSend = @{@"userID": userID,
                                              @"downloadURL":downloadURL.absoluteString,
                                              @"filename":filename,
                                              @"comments":comments,
                                              @"likes": @0};
            
            // write NSDictionary photo object to Firebase Database using AFNetworking
            NSString *DBUrlString = [NSString stringWithFormat: @"https://cameraandcloud-935e4.firebaseio.com/photos/%@.json",fileDate];
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            
            
            [manager PUT:DBUrlString parameters:photoDataToSend  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"success! %@\n",photoDataToSend);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error: %@", error);
            }];
 
            
            //DOWNLOAD from Firebase - everything in photos directory
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            
            [manager GET: @"https://cameraandcloud-935e4.firebaseio.com/photos.json" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            
                // put GET response into dictionary
                NSDictionary *parsedData = responseObject;
//                NSLog(@"\n\nJSON: %@\n\n", responseObject);

                self.photosArray = [[NSMutableArray alloc] init];
            
                // enumerate through nsdictionary
                for(id key in parsedData) {
                    
                    // add objects to photoArray directly from enumeration
                    [self.photosArray addObject: parsedData[key]];
                }
                NSLog(@"%@",self.photosArray);

            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
            
            [self saveMetaDataToPhotoObject: metaData];
            
        }
    }];
//    NSLog(@"%@",self.photosArray);
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    //cancel image picker controller
    [picker  dismissViewControllerAnimated:YES completion:NULL];
}

- (void) saveMetaDataToPhotoObject: (FIRStorageMetadata *)metaData {
    
    //initialize photo object
//    Photo *photoObject = [[Photo alloc] initWithUserID:userID andImage:photoImage andFilename:metaData.downloadTokens andDownloadURL:metaData.downloadURL andLikes:0 andComments:NUL];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
