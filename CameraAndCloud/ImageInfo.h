//
//  imageInfo.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 2/16/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

@interface ImageInfo : NSObject

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *imageDDPath;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *downloadURL;
@property int indexInImagesArray;


@end
