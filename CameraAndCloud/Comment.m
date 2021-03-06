//
//  Comment.m
//  CameraAndCloud
//
//  Created by Emiko Clark on 3/3/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import "Comment.h"

@implementation Comment


- (instancetype)initWithUsername: (NSString*) user andText: (NSString*) text
{
    self = [super init];
    if (self) {
        _username = user;
        _text = text;
    }
    return self;
}

@end
