//
//  imageInfo.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 2/16/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "ImageInfo.h"

@implementation ImageInfo : NSObject 


-(NSString *)description
{
    return [NSString stringWithFormat:@"filename:%@\nimageDDPath:%@\nuser:%@\ndownloadURL:%@\n", self.filename, self.imageDDPath,self.username,self.downloadURL];
}
@end
