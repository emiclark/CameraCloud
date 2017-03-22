//
//  Photo.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/11/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "Comment.h"

@interface Photo : NSObject

@property (nonatomic, strong) NSURL    *downloadURL;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *DDfilePath;
@property (nonatomic, strong) NSMutableArray <Comment*> *commentsArr;
@property (nonatomic, strong) NSMutableArray *likesArray;
@property (nonatomic, strong) NSString *username;
@property NSNumber * likes;
@property int indexInImagesArray;


- (Photo *) initWithEmail: (NSString *)userEmail andFilename:(NSString *)filename andDownloadURL:(NSURL *)fileDownloadURL    Username:(NSString *)username likes:(NSNumber *)likes andComments:(NSMutableArray*) comments andLikesArray: (NSString *)usersWhoLiked;
@end
