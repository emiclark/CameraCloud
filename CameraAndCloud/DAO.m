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
int picCount;


#pragma mark Initialize Setup Methods

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
    if (self)
        {
        // set references to firebase storage and database
        // create Firebase storage reference
        FIRStorage *storage = [FIRStorage storage];
        
        // Create a storage reference from our storage service
        self.storageRef = [storage referenceForURL: BASE_STORAGE_URL];
        
        // create Firebase database reference
        self.dbRef = [[FIRDatabase database] referenceFromURL: BASE_DATABASE_URL];
        }
    return self;
}

-(void) setupApp
{
    // initialize arrays and variables
    self.imagesArray = [[NSMutableArray alloc]init ];
    self.commentArray = [[NSMutableArray alloc]init];
    self.likesArray = [[NSMutableArray alloc]init];
    self.finishedDownloadingImages = YES;
    picCount = 0;
    
    // get Document DirectoryPath
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.DDpath = [path objectAtIndex:0];
    NSLog(@"Documents Directory path:%@",self.DDpath);
    
    // check if any photos saved to Documents Direcortory
    NSFileManager  *filemgr = [NSFileManager defaultManager];
    self.fileList = [filemgr contentsOfDirectoryAtPath: self.DDpath  error:nil];
    
    if (self.fileList.count > 0)
        {  /*
            Photos exist in Documents Directory.
            Iterate through fileList and initialize self.imagesArray with photos
            to later populate collection view */
            
            [self addPhotosInDDToImagesArray];
        }
    
    [self downloadCloudDataForAllPhotos];
}


-(void) addPhotosInDDToImagesArray
{
    for (NSString *file in self.fileList)
        {
        // create ImageInfo object and add to imagesArray
        ImageInfo *info = [[ImageInfo alloc] init];
        info.filename = [file stringByDeletingPathExtension];
        info.username = @"";
        info.downloadURL = @"";
        info.indexInImagesArray = 0;
        info.imageDDPath = [NSString stringWithFormat:@"%@/%@",self.DDpath, file];
        
        [self.imagesArray addObject: info];
        }
}

- (void) addDownloadedPhotosToImagesArray:(NSDictionary*)responseData
{
    //iterate through responseData. create info object, set values, add to imagesArray.
    for (NSString *key in responseData)
        {
        // create ImageInfo object and set values
        ImageInfo *imgInfo = [self createInfoObject:responseData WithFilename:key];
        
        [self.imagesArray addObject:imgInfo];
        
        // download photos from firebase and save to DocDir
        [self downloadPhotoWithFilename:imgInfo];
        }
}


#pragma mark download from Firebase methods

- (void) downloadCloudDataForAllPhotos
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
        picCount = (int)(responseData.count - self.fileList.count);
        
        if (self.fileList.count == 0 && responseData.count > 0)
            {
            // no photos in DocsDirectory but photos exists in Firebase.
            self.finishedDownloadingImages = NO;
            [self addDownloadedPhotosToImagesArray:responseData ];
            }
        else if (self.fileList.count > 0 && responseData.count > 0)
            {
            // photos exist in both DDirectory and Firebase - compare photos in firebase with photos in DDirecory and update info in imagesArray
            NSMutableString *fileInFireBase;
            if (picCount == 0)
                {
                // the count for photos is the same in Firebase and Documents Directory - update imagesArray for downloaded photos
                [self updateImagesArrayForAllDownloadedPhotos: responseData];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // send notification on main queue to to update
                    self.finishedDownloadingImages = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
                });
                }
            else {
                // the count for photos is the not the same in Firebase and Documents Directory
                for (NSString *key in responseData)
                    {
                    BOOL fileFound = NO;
                    
                    // get base filename
                    fileInFireBase = (NSMutableString *)key;
                    
                    // for each photo in Firebase,iterate through fileList & populate imagesArray.
                    for (int i=0; i <= self.fileList.count; i++){
                        
                        if (fileFound == NO && i == self.fileList.count && picCount < 0)
                            {
                            // all photos downloaded and added to imagesArray, stop activity indicator from spinning, create info object and populate with user, downloadURL, DDpath info
                            ImageInfo *info = [self createInfoObject:responseData WithFilename:key];
                            [self.imagesArray addObject: info];
                            [self downloadPhotoWithFilename: info];
                            
                            fileFound = YES;
                            self.finishedDownloadingImages = NO;
                            }
                        else
                            {
                            // check downloaded photo with fileList and then update imagesArray
                            NSString *fileInDD = [self.fileList[i] stringByDeletingPathExtension];
                            if ([fileInFireBase isEqualToString: fileInDD])
                                {
                                // downloaded photo found in both Documents Directory - create info object and populate with user, downloadURL, DDpath info
                                ImageInfo *info = [self createInfoObject:responseData WithFilename:fileInDD];
                                [self updateImagesArrayWithDownloadedData:info];
                                
                                fileFound = YES;
                                break;
                                }
                            }
                    }
                    }
                [DAO printImagesArray: self.imagesArray];
            }
            }
    }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
     NSLog(@"failure getting responseObject -or- no photos in Firebase, begin by uploading photos");
     
     dispatch_async(dispatch_get_main_queue(),^{
         
         if (self.fileList.count == 0)
             {
             // no photos in firebase storage or DDirectory. send alert message to user to upload photos
             self.finishedDownloadingImages = YES;
             NSLog(@"No photos in Firebase or saved on iPhone. Begin by uploading photos");
             
             // send notification on main queue to show alert message to begin with uploading photos
             NSDictionary *alertParams = [[NSDictionary alloc] initWithObjectsAndKeys: @"There are no photos in the Database.", @"alertTitle", @"Begin by uploading your images.", @"msg", nil];
             [[NSNotificationCenter defaultCenter]postNotificationName:@"showAlert" object:self userInfo:alertParams];
             }
     });
     }];
}


- (void) downloadPhotoWithFilename: (ImageInfo*) info
{
    // download photo and save to Documents Directory folder
    
    // Create a reference to the file you want to download
    NSString *urlString = [NSString stringWithFormat:@"images/%@.jpg", info.filename];
    NSString *photoPath = [NSString stringWithFormat:@"%@/%@.jpg", self.DDpath, info.filename];
    self.imageRef = [self.storageRef child:urlString];
    
    // Download in memory with 10MB max size (10 * 1024 * 1024 bytes)
    [self.imageRef dataWithMaxSize:10 * 1024 * 1024 completion:^(NSData *data, NSError *error) {
        if (error != nil)
            {
            // Uh-oh, an error occurred!
            NSLog(@" download error - : %@", [error localizedDescription]);
            self.finishedDownloadingImages = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
            }
        else
            {
            // successful download - write photo to documents directory
            [data writeToFile:photoPath atomically:YES];
            
            // decrement picCount. When (picCount=0), all photos are downloaded. Set flag that all downloads complete & send notification to update collection view
            
            picCount--;
            if (picCount <= 0)
                {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // send notification to update collection view
                    self.finishedDownloadingImages = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"Update" object:self userInfo:nil];
                });
                }
            }
    }];
}


- (void) downloadDataForSelectedPhoto:(ImageInfo *)info
{
    // download comments & likes data for selected photo
    self.photoDataForUser = [[Photo alloc]init];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSString *userData = [NSString stringWithFormat:@"%@/users/%@/%@.json", BASE_DATABASE_URL, info.username, info.filename];
    
    [manager GET:userData parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // get user information for specific photo
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.commentArray removeAllObjects];
            [self.likesArray removeAllObjects];
            
            // populate PhotoDetailViewController with user's photo info from dictionary
            self.photoDataForUser.DDfilePath = [NSString stringWithFormat:@"%@/%@.jpg",self.DDpath,[responseObject objectForKey:@"filename"]];
            self.photoDataForUser.filename = [responseObject objectForKey:@"filename"];
            self.photoDataForUser.likes = [responseObject objectForKey:@"likes"];
            self.photoDataForUser.username = [responseObject objectForKey:@"username"];
            self.photoDataForUser.downloadURL = [responseObject objectForKey:@"downloadURL"];
            self.photoDataForUser.userEmail = [responseObject objectForKey:@"email"];
            self.photoDataForUser.indexInImagesArray = info.indexInImagesArray;
            
            // populate comments array
            self.photoDataForUser.commentsArr = [[NSMutableArray alloc]init];
            NSArray *tempCommentsArr = [responseObject objectForKey:@"comments"];
            
            if([tempCommentsArr  isEqual: @""]) {
                // no comments for photo
                NSLog(@"Nothing in Comments array");
            }
            else
                {
                // comments exists, add them to array
                for (NSDictionary *photo in tempCommentsArr)
                    {
                    Comment *comment = [[Comment alloc] initWithUsername:[photo objectForKey:@"username"] andText:[photo objectForKey:@"text"]];
                    [self.commentArray addObject:comment];
                    }
                }
            self.photoDataForUser.commentsArr = self.commentArray;
            
            // check if any likes in likesArray
            NSArray *tempLikesArr = [responseObject objectForKey:@"likesArray"];
            
            if([tempLikesArr  isEqual: @""]) {
                // no comments for photo
                NSLog(@"Nothing in likes array");
                self.photoDataForUser.likesArray = [[NSMutableArray alloc]init];
            }
            else
                {
                // there are likes for photo
                self.photoDataForUser.likesArray = [[NSMutableArray alloc]initWithArray:[responseObject objectForKey:@"likesArray"]];
                }
            
            // send notification to push to photo detail view controller
            dispatch_async(dispatch_get_main_queue(), ^{
                // send notification to update collection view
                self.finishedDownloadingImages = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Segue" object:self userInfo:nil];
            });
        });
    }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"ERROR: downloading User data for photo:%@-",error);
         }];
    
}

#pragma mark upload/update to Firebase Methods

- (ImageInfo*) uploadNewPhoto:(UIImage *)selectedImage withImageInfo: (ImageInfo*)info;
{
    // upload new image to Firebase Storage and return ImageInfo with downloadURL
    NSData *data = UIImageJPEGRepresentation(selectedImage, 0.1);
    
    self.imageRef = [self.storageRef child: [NSString stringWithFormat:@"/images/%@.jpg",info.filename]];
    
    // create metadata
    FIRStorageMetadata *metaData = [[FIRStorageMetadata alloc]init];
    metaData.contentType = @"images/jpg";
    
    // Upload the file to the path "images/filename.jpg"
    [self.imageRef putData:data metadata: metaData completion: ^(FIRStorageMetadata *metadata, NSError *error)
     {
     if (error == nil)
         {
         // upload photo success,  show alert box for upload success
         NSString *alertTitle = @"Upload Successful";
         NSString *msg = @"Photo uploaded sucessfully!";
         
         NSDictionary *alertParams = [[NSDictionary alloc] initWithObjectsAndKeys: alertTitle, @"alertTitle", msg, @"msg", nil];
         
         NSLog(@"Success: %@",alertParams);
         
         // send notification on main queue to show alert message from TakePhotoViewController
         dispatch_async(dispatch_get_main_queue(),^{
             [[NSNotificationCenter defaultCenter]postNotificationName:@"showAlert" object:self userInfo:alertParams];
         });
         
         // metadata contains file metadata such as size, content-type, and download URL.
         NSURL *url  = [metadata.downloadURLs objectAtIndex:0];
         info.downloadURL = [url absoluteString];
         
         // write info to database
         [self registerFilenameForNewPhoto: info];
         [self writeDataForNewPhoto: info];
         }
     else
         {
         // upload photo failure,  send notification and alertInfo for upload failure
         NSString *alertTitle = @"Upload Failed.";
         NSString *msg = @"Problem uploading the photo.";
         NSDictionary *alertParams = [[NSDictionary alloc] initWithObjectsAndKeys:alertTitle, @"alertTitle", msg, @"msg", nil];
         [[NSNotificationCenter defaultCenter]postNotificationName:@"showAlert" object:self userInfo:alertParams];
         }
     }];
    return info;
}


- (void) updateDataForSelectedPhoto:(Photo *) info
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    // create comments array to send
    NSMutableArray *commentArrayToSend = [[NSMutableArray alloc] init];
    
    for (Comment *arr in info.commentsArr ) {
        NSString *user = arr.username;
        NSString *text = arr.text;
        NSDictionary *commentDict = [[NSDictionary alloc] initWithObjectsAndKeys:user, @"username", text, @"text", nil];
        [commentArrayToSend addObject: commentDict];
    }
    
    NSDictionary *post;
    
    if (info.likesArray.count == 0){
        post = [[NSDictionary alloc] initWithObjectsAndKeys: info.downloadURL, @"downloadURL", info.userEmail, @"email", info.filename, @"filename", info.likes, @"likes", info.username, @"username", commentArrayToSend, @"comments", @"", @"likesArray", nil ];
    }
    else
        {
        post = [[NSDictionary alloc] initWithObjectsAndKeys: info.downloadURL, @"downloadURL", info.userEmail, @"email", info.filename, @"filename", info.likes, @"likes", info.username, @"username", commentArrayToSend, @"comments", info.likesArray, @"likesArray", nil ];
        }
    
    NSString *FBpath = [NSString stringWithFormat:@"%@/users/%@/%@.json",BASE_DATABASE_URL, info.username, info.filename ];
    
    [manager PUT:FBpath parameters:post success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"update photo data - success");
    }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
     NSLog(@"update photo data - failed");
     }];
}


#pragma mark write/delete to Firebase Methods


- (void) registerNewUser:(NSString*) user andUUID:(NSString*) uuidString
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


- (void) registerFilenameForNewPhoto: (ImageInfo *) info
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
      NSLog(@"fail PUT - error %@", error.localizedDescription);
      }];
     }
           failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
     // error writing to baseURL/files/filename
     NSLog(@"fail PATCH - error %@", error.localizedDescription);
     }];
}


- (void) writeDataForNewPhoto: (ImageInfo *) info
{
    // write user information: (downloadURL, email, photo filename, likes, comments,username) to Firebase /users
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:@"email"];
    
    // create dictionary
    NSDictionary *post = [[NSDictionary alloc] initWithObjectsAndKeys: info.downloadURL, @"downloadURL", email, @"email", info.filename, @"filename", @0, @"likes", @"", @"comments", username, @"username", @"",@"likesArray", nil];
    
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


- (void) deletePhotoAndData:(Photo*)photoInfo
{
    // Create a reference to photo in firebase storage to delete
    NSString *storagePhotoID = [NSString stringWithFormat: @"/images/%@.jpg", photoInfo.filename];
    self.imageRef = [self.storageRef child: storagePhotoID];
    
    // Delete the file
    [self.imageRef deleteWithCompletion:^(NSError *error){
        if (error == nil)
            {
            // File deleted successfully
            NSLog(@"deletePhotoFromFireBase Storage successful!!");
            } else {
                // Uh-oh, an error occurred!
                NSLog(@"deletePhotoFromFireBase Storage failed!!");
            }
    }];
    
    // Create a reference to firebase database to delete: users/username/filename
    NSString *usersID = [NSString stringWithFormat:@"users/%@/%@", photoInfo.username, photoInfo.filename];
    [[self.dbRef child:usersID] setValue:nil];
    
    // Create a reference to firebase database to delete: lookup/files/filename
    NSString *lookupID = [NSString stringWithFormat:@"lookup/files/%@", photoInfo.filename];
    [[self.dbRef child:lookupID] setValue:nil];
}



#pragma mark Utility Methods


- (void) getDocumentDirectoryPath
{
    // check if Document Directory contains files
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.DDpath = [path objectAtIndex:0];
    NSLog(@"DDpath: %@",self.DDpath);
}

- (ImageInfo*) createInfoObject:(NSDictionary*)responseData WithFilename:(NSString*)name
{
    // populate imagesArray with missing info: user, downloadURL
    ImageInfo *info = [[ImageInfo alloc]init];
    
    info.filename = name;
    info.indexInImagesArray = 0;
    info.downloadURL = [[responseData objectForKey:name] objectForKey:@"downloadURL"];
    info.username = [[responseData objectForKey:name] objectForKey:@"username"];
    info.imageDDPath = [NSString stringWithFormat: @"%@/%@.jpg",self.DDpath,info.filename];
    return info;
}

- (void) saveImageToDD: (UIImage*) image ToDDirectoryWithFilename:(NSString *)filePath
{
    // write image data to DDirectory
    NSData* data = UIImageJPEGRepresentation(image, 1.0);
    
    // Write the file in the documents directory
    [data writeToFile: filePath atomically:YES];
    NSLog(@"success writing file to DDirectory: %@\n",filePath);
}


- (void) updateImagesArrayForAllDownloadedPhotos:(NSDictionary *) responseData
{
    //parse through responseData and populate info object
    NSLog(@"\nresponseData: %@",responseData);
    for (NSString *key in responseData)
        {
        ImageInfo *info = [self createInfoObject:responseData WithFilename:key];
        [self updateImagesArrayWithDownloadedData: info];
        }
}

- (void) updateImagesArrayWithDownloadedData:(ImageInfo *)info
{
    // iterate thru imagesArray and update info object with downloaded information
    for (int i=0; i<self.imagesArray.count; i++) {
        if ([[[self.imagesArray objectAtIndex: i] filename] isEqualToString: info.filename] )
            {
            [self.imagesArray replaceObjectAtIndex:i withObject:info];
            break;
            }
    }
    NSLog(@"updated info:%@",info);
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

- (BOOL) checkIfUserLikedPhoto: (Photo *) photoInfo
{
    // check if current user liked the photo
    NSString *userinNSDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    
    // convert NSArray into NSSet
    NSSet *setOfUsersWhoLiked = [[NSSet alloc] initWithArray: [photoInfo valueForKey:@"likesArray"]];
    BOOL contains = [setOfUsersWhoLiked containsObject: userinNSDefaults];
    return contains;
}

+ (void) printImagesArray: (NSMutableArray *)array
{
    for(id item in array)
        NSLog(@"\n\nimagesArray: %@\n\n",item);
}

@end

