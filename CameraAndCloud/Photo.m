//
//  Photo.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 1/11/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "Photo.h"

@implementation Photo

- (Photo *) initWithEmail: (NSString *)userEmail andFilename:(NSString *)filename andDownloadURL:(NSURL *)fileDownloadURL    Username:(NSString *)username likes:(NSNumber *)likes andComments:(NSMutableArray*) comments {
    
    self = [super init];
    
    if (self) {
        self.userEmail = userEmail;
        self.filename = filename;
        self.downloadURL = fileDownloadURL;
        if (self.likes>0){
            self.likes = likes;
        }
        else
            self.likes = 0;
        self.commentsArr = [[NSMutableArray alloc] initWithObjects:@"", nil];
        self.username = username;
    }
    return  self;
    
}

@end
