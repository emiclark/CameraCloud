//
//  DAO.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/30/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "DAO.h"


#define  BASE_STORAGE_URL @"gs://cameraandcloud-935e4.appspot.com"
#define  BASE_DATABASE_URL @"https://cameraandcloud-935e4.firebaseio.com"


@implementation DAO

static DAO *sharedInstance = nil;
NSString  const * alertNotification = @"showAlert";
int picCount;


#pragma mark Singleton Methods

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithData];
    });
    return sharedInstance;
}

- (instancetype)initWithData
{
    
    self = [super init];
    if (self) {
        // set references to firebase storage and database
        self.imageRef = [self setFirebaseStorageReferences];
        self.dbRef  = [self setFirebaseDBReferences];

        [self doWhenAppLaunches];
    }
    return self;
}

- (void) doWhenAppLaunches
{
    self.imagesArray = [[NSMutableArray alloc]init ];
    self.commentArray = [[NSMutableArray alloc]init];
    
    self.finishedDownloadingImages = YES;
    
    // get Document DirectoryPath
    [self getDocumentDirectoryPath];

    NSFileManager  *filemgr = [NSFileManager defaultManager];

    // assign filelist to imagesArray
    NSArray *fileList = [filemgr contentsOfDirectoryAtPath: self.DDpath  error:nil];
    
    if (fileList.count > 0) {
        //iterate through fileList and populate self.imagesArray for collection view
        for (NSString *file in fileList) {
            NSLog(@"file: %@",file);
            
            // create ImageInfo object and set values
            ImageInfo *info = [[ImageInfo alloc] init];
            info.filename = [file stringByDeletingPathExtension];
            info.username = @"";
            info.downloadURL = @"";
            info.imageDDPath = [NSString stringWithFormat:@"%@/%@",self.DDpath, file];
            
            [self.imagesArray addObject: info];
        }
        // send notification to update collection view
        [NSNotification notificationWithName:@"Update" object:nil userInfo:nil];
        
    }
    // download cloud Data for photos
    [self downloadCloudDataForPhotos: fileList];
    
}


- (void) downloadCloudDataForPhotos: (NSArray *) fileList
{
    // download names of photos from /lookup/files.json in Firebase storage and store in self.photoDict
    self.finishedDownloadingImages = NO;
    
    // setup networking params
    NSString *refURL = [NSString stringWithFormat:@"%@/lookup/files.json",BASE_DATABASE_URL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.requestSerializer  = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // Download photo info in FBDatabase: BASE_URL/lookup/files/filename
    [manager GET:refURL  parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // cast id to nsdictionary to use responseData.count
        NSDictionary *responseData = responseObject;
        
        // picCount = how many photos needs to be downloaded from firebase
        picCount = (int)(responseData.count - fileList.count);

        if (fileList.count == 0 && responseData.count > 0)
        {
            // no photos in DocsDirectory but photos exists in Firebase.
            self.finishedDownloadingImages = NO;
        
            //iterate through responseData for photo information and store in info object
            for (NSString *key in responseData){

                // create ImageInfo object and set values
                ImageInfo *info = [[ImageInfo alloc]init];
                info.filename = key;
                info.downloadURL = [[responseData objectForKey:key] objectForKey:@"fileDownloadURL"];
                info.username = [[responseObject objectForKey: key] objectForKey:@"username"];
                info.imageDDPath = [NSString stringWithFormat: @"%@/%@.jpg",self.DDpath,info.filename];
                
                // add to imagesArray
                [self.imagesArray addObject:info];
                
                NSLog(@"info:%@",info);
                [DAO printImagesArray: self.imagesArray];
                
                // download photos from firebase and save to DocDir
                [self downloadPhotoWithFilename:info];
            }
        }
        
        
        else if (fileList.count > 0 && responseData.count > 0) {
            // photos exist in DDirectory and Firebase
            
            // check if photo in firebase is also in DDirecory
            NSMutableString *fileInFireBase;
            if (picCount == 0) {
                // update imagesArray for all images that are downloaded
                [self updateImagesArray: responseData];
                
                self.finishedDownloadingImages = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
            }
            else {
                // iterate through all keys in self.photoDict
                for (NSString *key in responseData) {
                    BOOL fileFound = NO;

                    // get base filename
                    fileInFireBase = (NSMutableString *)key;

                    // for each photo in Firebase,iterate through fileList & populate imagesArray.
                    for (int i=0; i <= fileList.count; i++){

                        if (fileFound == NO && i == fileList.count && picCount>0) {
                            ImageInfo *info = [[ImageInfo alloc]init];
                            self.finishedDownloadingImages = NO;

                            // create ImageInfo object and set values
                            info.filename = key;
                            info.downloadURL = [[responseData objectForKey:key] objectForKey:@"downloadURL"];
                            info.username = [[responseData objectForKey:key] objectForKey:@"username"];
                            info.imageDDPath = [NSString stringWithFormat: @"%@/%@.jpg",self.DDpath,info.filename];
                            [self.imagesArray addObject: info];
                            [self downloadPhotoWithFilename: info];

                            fileFound = YES;
                        }
                        else {
                            // check photo in Firebase against fileList
                            NSString *fileInDD = [fileList[i] stringByDeletingPathExtension];
                            if ([fileInFireBase isEqualToString: fileInDD]){
                                // photo exists in both Documents Directory and Firebase
                                
                                // populate imagesArray with missing info: user, downloadURL
                                ImageInfo *info = [[ImageInfo alloc]init];
                                
                                info.filename = fileInDD;
                                info.downloadURL = [[responseData objectForKey:fileInDD] objectForKey:@"downloadURL"];
                                info.username = [[responseData objectForKey:fileInDD] objectForKey:@"username"];
                                info.imageDDPath = [NSString stringWithFormat: @"%@/%@.jpg",self.DDpath,info.filename];
                                
                                NSLog(@"info:%@",info);
                                
                                [self updateImagesArrayWithInfo:info];
                                [DAO printImagesArray: self.imagesArray];
                                
                                fileFound = YES;
                                break;
                            }
                        }
                    }
                }
            }
        }

        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"failure getting responseObject or no photos in Firebase, begin by uploading photos");
        if (fileList.count == 0) {
            // no photos in firebase storage or DDirectory. send alert message to user to upload photos
            NSLog(@"No photos in Firebase or saved on iPhone. Begin by uploading photos");
            self.finishedDownloadingImages = YES;
            
            // upload photo success,  show alert box for upload success
            NSString *alertTitle = @"There are no photos uploaded.";
            NSString *msg = @"Begin by uploading your images.";
            NSDictionary *alertParams = [[NSDictionary alloc] initWithObjectsAndKeys: alertTitle, @"alertTitle", msg, @"msg", nil];
            
            // send notification on main queue to show alert message from TakePhotoViewController
            [[NSNotificationCenter defaultCenter]postNotificationName:@"showAlert" object:nil userInfo:alertParams];
        }
    }];
}

- (void) updateImagesArray:(NSDictionary *) responseData
{
    NSLog(@"\nresponseData: %@",responseData);
    for (NSString *key in responseData) {
        ImageInfo *info = [[ImageInfo alloc] init];
        info.filename = [[responseData objectForKey: key] objectForKey:@"filename"];
        info.username  = [[responseData objectForKey:key] objectForKey:@"user"];
        info.downloadURL  = [[responseData objectForKey:key] objectForKey:@"downloadURL"];
        info.imageDDPath = [NSString stringWithFormat:@"%@/%@.jpg",self.DDpath, info.filename];
        [self updateImagesArrayWithInfo: info];
    }
}


#pragma mark Download Methods

- (void) downloadPhotoWithFilename: (ImageInfo*) info
{
    // Create a reference to the file you want to download
    // set photoFilename as the filename to save to DocDir folder
    
    NSLog(@"downloadPhotoWithFilename:info: %@",info);
    
    NSString *urlString = [NSString stringWithFormat:@"images/%@.jpg", info.filename];
    NSString *photoPath = [NSString stringWithFormat:@"%@/%@.jpg", self.DDpath, info.filename];

    // Create a reference to the file you want to download
    self.imageRef = [self.storageRef child: urlString];
   
    NSLog(@"\n\n imageRef:%@\n\n info.filename: %@\n\n  DDpath: %@\n\ninfo.downloadURL:%@\n\n", self.imageRef, info.filename,  photoPath, info.downloadURL);
    
    // Download in memory with 10MB max size (10 * 1024 * 1024 bytes)
    [self.imageRef dataWithMaxSize:10 * 1024 * 1024 completion:^(NSData *data, NSError *error){
        if (error != nil) {
            // Uh-oh, an error occurred!
            NSLog(@" download error - : %@", [error localizedDescription]);
            
        } else {
            // success with download
            // Write the file in the documents directory
            [data writeToFile:photoPath atomically:YES];
            NSLog(@"\n\nSuccess with download:%@",photoPath);
            
            // decrement picCount. When (picCount=0), all photos are downloaded.
            // Then send notification to update collection view and stop activity view.
            picCount--;
            if (picCount <= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // send notification to update collection view
                    self.finishedDownloadingImages = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
                });
            }
        }
    }];
}


- (void) downloadDataForSelectedPhotoFromFirebaseUsersTable:(ImageInfo *)info
{
    self.photoDataForUser = [[Photo alloc]init];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    NSString *userData = [NSString stringWithFormat:@"%@/users/%@/%@.json", BASE_DATABASE_URL, info.username, info.filename];
    
// >> FIX ERROR: >>  https://cameraandcloud-935e4.firebaseio.com/users/(null)/030817114619.json
    
    
    [manager GET:userData parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // get user information for specific photo
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.commentArray removeAllObjects];
            
            // populate PhotoDetailViewController with user's photo info from dictionary
            self.photoDataForUser.DDfilePath = [NSString stringWithFormat:@"%@/%@.jpg",self.DDpath,[responseObject objectForKey:@"filename"]];
            self.photoDataForUser.filename = [responseObject objectForKey:@"filename"];
            self.photoDataForUser.likes = [responseObject objectForKey:@"likes"];
            self.photoDataForUser.username = [responseObject objectForKey:@"username"];
            self.photoDataForUser.downloadURL = [responseObject objectForKey:@"downloadURL"];
            self.photoDataForUser.userEmail = [responseObject objectForKey:@"email"];
            
            // populate comments array
            self.photoDataForUser.commentsArr = [[NSMutableArray alloc]init];

            NSArray *tempCommentsArr = [responseObject objectForKey:@"comments"];
            
            if([tempCommentsArr  isEqual: @""])
            {
                // no comments for photo
                NSLog(@"Nothing in Comments array");
            }
            else
            {
                // comments exists, add them to array
                for (NSDictionary *photo in tempCommentsArr)
                {
                    Comment *comment = [[Comment alloc] initWithUsername:[photo objectForKey:@"username"] andText:[photo  objectForKey:@"text"]];
                    [self.commentArray addObject:comment];
                }
            }
            self.photoDataForUser.commentsArr = self.commentArray;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Segue" object:self userInfo:nil];
        });
    }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"ERROR: downloading User data for photo:%@-",error);
         }];

}

-(UIImage *)resizeImage:(UIImage *)image
{
    float i_width = image.size.width/4;
    float oldWidth = image.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = image.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [image drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark Write To Firebase Methods

- (ImageInfo*) uploadImageToFirebase:(UIImage *)selectedImage withImageInfo: (ImageInfo*)info;
{
    // upload image to Firebase Storage
    NSData *data = UIImageJPEGRepresentation(selectedImage, 0.1);
    
    self.imageRef = [self.storageRef child: [NSString stringWithFormat:@"images/%@.jpg",info.filename]];
    NSLog(@"uploadimage>>: %@\n",self.imageRef);
    
    // create metadata
    FIRStorageMetadata *metaData = [[FIRStorageMetadata alloc]init];
    metaData.contentType = @"images/jpg";
    
    // Upload the file to the path "images/filename.jpg"
    [self.imageRef putData:data metadata: metaData completion: ^(FIRStorageMetadata *metadata, NSError *error)
     {
     if (error == nil)
         {
         // upload photo success,  show alert box for upload success
         NSString *alertTitle = @"Upload";
         NSString *msg = @"image uploaded - Success!";
         
         NSDictionary *alertParams = [[NSDictionary alloc] initWithObjectsAndKeys: alertTitle, @"alertTitle", msg, @"msg", nil];
         
         NSLog(@"Success: %@",alertParams);
         
         // send notification on main queue to show alert message from TakePhotoViewController
         dispatch_async(dispatch_get_main_queue(),^{
             [[NSNotificationCenter defaultCenter]postNotificationName:@"showAlert" object:nil userInfo:alertParams];
         });
         
         // metadata contains file metadata such as size, content-type, and download URL.
         NSURL *url  = [metadata.downloadURLs objectAtIndex:0];
         info.downloadURL = [url absoluteString];
         
         // write info to database
         [self writeToFireBaseLookupUsersTable: info];
         [self writeUserDataToFirebaseUsersTable: info];
         }
     else
         {
         // upload photo failure,  send notification and alertInfo for upload failure
         NSString *alertTitle = @"Upload Failed.";
         NSString *msg = @"There was a problem with the upload.";
         NSDictionary *alertParams = [[NSDictionary alloc] initWithObjectsAndKeys:alertTitle, @"alertTitle", msg, @"msg", nil];
         [[NSNotificationCenter defaultCenter]postNotificationName:@"showAlert" object:nil userInfo:alertParams];
         }
     }];
    return info;
    
}


- (void) writeToFireBaseLookupUsersTable: (ImageInfo *) info
{
    // write info object to FirebaseDB: /lookup/files/key
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *key = [info.filename stringByDeletingPathExtension];
    NSString *lookupID = [NSString stringWithFormat:@"%@/lookup/files/%@.json", BASE_DATABASE_URL, key];
    
    NSDictionary *sendInfo = @{@"DDpath": self.DDpath, @"filename":info.filename, @"username":info.username, @"downloadURL":info.downloadURL};
    
    [manager PATCH: lookupID parameters: sendInfo success: ^(NSURLSessionDataTask *task, id responseObject)
     {
         // success writing to baseURL/files/filename
         NSLog(@"success lookupID PUT responseObject: %@", responseObject);
         
         // write user uuid info to database
         NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
         NSString *uuidString = [[NSUserDefaults standardUserDefaults] objectForKey:@"uid"];
         
         // get uid from nsuserdefaults
         NSString *uidPath = [NSString stringWithFormat:@"%@/lookup/users/%@.json", BASE_DATABASE_URL,uuidString];
         
         // create dictionary
         NSDictionary *uidDict = [[NSDictionary alloc] initWithObjectsAndKeys:username, uuidString, nil];
     
     // write uid and user info to /lookup/uid/
     [manager PUT: uidPath parameters: uidDict success: ^(NSURLSessionDataTask *task, id responseObject)
      {
          NSLog(@"success UUID PUT responseObject: %@", responseObject);
      }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
      {
      NSLog(@"fail PUT");
      NSLog(@"error %@", error.localizedDescription);
      }];
     }
     // error writing to baseURL/files/filename
           failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
     NSLog(@"fail PATCH");
     NSLog(@"error %@", error.localizedDescription);
     }];
}


- (void) writeUserDataToFirebaseUsersTable: (ImageInfo *) info
{
    // write user information: (downloadURL, email, photo filename, likes, comments,username) to Firebase /users
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:@"email"];
    
    // create dictionary
    NSDictionary *post = [[NSDictionary alloc] initWithObjectsAndKeys: info.downloadURL, @"downloadURL", email, @"email", info.filename, @"filename", @0, @"likes", @"", @"comments", username, @"username", nil];
    
    // write NSDictionary photo object to Firebase Database using AFNetworking
    NSString *userInfoString = [NSString stringWithFormat: @"%@/users/%@/%@.json",BASE_DATABASE_URL, username, self.fileDate];
    
    [manager PUT:userInfoString parameters: post  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
     {
     NSLog(@"\nsuccess userInfoString%@\n",responseObject);
     }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
     NSLog(@"error: %@", error);
     }];
}



+ (void) writeNewUserToFirebaseLookupUsersTable:(NSString*) user andUUID:(NSString*) uuidString
{
    // write new username and corresponding uuid to /lookup/users/uuid
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    // create dictionary
    NSDictionary *uidDict = [[NSDictionary alloc] initWithObjectsAndKeys: user, uuidString, nil];
    NSString *uidPath = [NSString stringWithFormat:@"%@/lookup/users/%@.json",BASE_DATABASE_URL, uuidString];
    
    // write uid and user info to /lookup/uid/
    [manager PUT: uidPath parameters: uidDict success: ^(NSURLSessionDataTask *task, id responseObject)
     {
     NSLog(@"success UUID PUT responseObject: %@", responseObject);
     }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
     NSLog(@"fail PUT");
     }];
}

+ (void) updateDataForSelectedPhotoToFirebaseUsersTable:(Photo *) info
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSMutableArray *commentArrayToSend = [[NSMutableArray alloc] init];
    
    for (Comment *arr in info.commentsArr ) {
        NSString *user = arr.username;
        NSString *text = arr.text;
        NSDictionary *commentDict = [[NSDictionary alloc] initWithObjectsAndKeys:user, @"username", text, @"text", nil];

        [commentArrayToSend addObject: commentDict];
    }

    
    NSDictionary *post = [[NSDictionary alloc] initWithObjectsAndKeys: info.downloadURL, @"downloadURL", info.userEmail, @"email", info.filename, @"filename", info.likes, @"likes", info.username, @"username", commentArrayToSend, @"comments",  nil ];
    
    NSString *FBpath = [NSString stringWithFormat:@"%@/users/%@/%@.json",BASE_DATABASE_URL, info.username, info.filename ];
    
    [manager PUT:FBpath parameters:post success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"update photo data - success");
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"update photo data - failed");
    }];
    
    
}


#pragma mark Utility Methods

- (FIRStorageReference *) setFirebaseStorageReferences
{
    // create Firebase storage reference
    FIRStorage *storage = [FIRStorage storage];
    
    // Create a storage reference from our storage service
    self.storageRef = [storage referenceForURL: BASE_STORAGE_URL];
    
    // create child reference 'images' root reference
    self.imageRef = [self.storageRef child:@"images"];
    
    return self.imageRef;

}

- (FIRDatabaseReference *) setFirebaseDBReferences
{
    // create Firebase DB reference
    self.dbRef = [[FIRDatabase database] reference];
    return self.dbRef;
}


- (void) getDocumentDirectoryPath
{
    // check if Document Directory contains files
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.DDpath = [path objectAtIndex:0];
    NSLog(@"DDpath: %@",self.DDpath);
}


- (NSString *) createFilename
{
    // create filename for selectedImage using date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MMddyyHHmmss"];
    self.fileDate = (NSMutableString *)[dateFormatter stringFromDate:[NSDate date]];
    self.filename = [NSString stringWithFormat: @"%@",self.fileDate];
    NSLog(@"filename: %@",self.filename);
    return self.filename;
}


- (void) saveImage: (UIImage*) image ToDDirectoryWithFilename:(NSString *)filePath
{
    // write image data to DDirectory
    NSData* data = UIImageJPEGRepresentation(image, 1.0);

    // Write the file in the documents directory
    [data writeToFile: filePath atomically:YES];
    NSLog(@"success writing file to DDirectory: %@\n",filePath);
}


+ (void) printImagesArray: (NSMutableArray *)array
{
    for(id item in array) {
        NSLog(@"\n\nimagesArray: %@\n\n",item);
    }
}


- (void) updateImagesArrayWithInfo:(ImageInfo *)info
{
    // iterate thru imagesArray and update dictionary with info object
    for (int i=0; i<self.imagesArray.count; i++){
        if ([[[self.imagesArray objectAtIndex: i] filename] isEqualToString: info.filename] ) {
            [self.imagesArray replaceObjectAtIndex:i withObject:info];
            break;
        }
    }
    NSLog(@"updated info:%@",info);
    [DAO printImagesArray: self.imagesArray];
}

@end

